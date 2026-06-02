"""
train_models.py
Prior Authorization Intelligence System (PAIS) - Phase 6

Standalone training script for GitHub reproducibility.
Run this once from the project root to regenerate app/models/ artifacts
from the synthetic PA dataset.

Usage:
    python3 app/train_models.py

Outputs written to app/models/:
    delay_model.pkl       -- GradientBoostingClassifier pipeline
    denial_model.pkl      -- LogisticRegression pipeline
    feature_metadata.json -- Feature lists, thresholds, LR coefficients

Requirements:
    pip install -r app/requirements.txt

NOTES:
- All data is synthetic. No PHI. No real payer records.
- Models are decision-support tools only. They do not approve or deny care.
- Trained on full 25,000-row dataset for final deployment.
  See 05_delay_risk_model.ipynb and 06_denial_risk_model.ipynb for evaluation
  methodology including holdout metrics and cross-validation.
- Thresholds (DELAY_HIGH=0.193, DENIAL_HIGH=0.052) were selected in Phase 5
  to achieve recall >= 0.75 (delay) and >= 0.70 (denial) on the test split.
  See threshold_selection_notes.md for full rationale.
"""

import os
import sys
import json
import pickle
import warnings
import numpy as np
import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression

warnings.filterwarnings('ignore')

# Paths
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR     = os.path.join(PROJECT_ROOT, "data")  # CSVs live in data/
MODEL_DIR    = os.path.join(SCRIPT_DIR, "models")

os.makedirs(MODEL_DIR, exist_ok=True)

# Feature lists
CAT_FEATURES = [
    'request_type', 'submission_channel', 'service_category', 'procedure_group',
    'provider_type', 'network_status', 'provider_risk_segment', 'plan_type',
    'age_band', 'risk_level', 'region', 'submitted_day_of_week',
]
NUM_FEATURES = [
    'estimated_cost', 'avg_incomplete_submission_rate', 'avg_response_time_days',
    'chronic_condition_count', 'member_tenure_months',
]
BOOL_FEATURES = [
    'documentation_complete', 'auto_eligible', 'clinical_review_required',
    'previous_denial_history',
]
ALL_FEATURES = CAT_FEATURES + NUM_FEATURES + BOOL_FEATURES

# Leakage-excluded fields (never used as features - known only after decision):
# decision, decision_time_days (as feature), denial_reason, final_outcome,
# action_recommended_initial, appeal_id, appealed, appeal_outcome,
# pended_flag, reviewer_type

# Model hyperparameters - match evaluated settings in notebooks
DELAY_PARAMS = dict(
    n_estimators=200, max_depth=4, learning_rate=0.05,
    subsample=0.8, random_state=42
)
DENIAL_PARAMS = dict(
    max_iter=1000, class_weight='balanced', C=1.0,
    solver='lbfgs', random_state=42
)

# Operating thresholds from Phase 5 (threshold_selection_notes.md)
DELAY_THRESHOLD  = 0.193   # recall >= 0.75 on test split
DENIAL_THRESHOLD = 0.052   # recall >= 0.70 on test split


def build_preprocessor():
    return ColumnTransformer([
        ('cat',  OneHotEncoder(handle_unknown='ignore', sparse_output=False), CAT_FEATURES),
        ('num',  StandardScaler(), NUM_FEATURES),
        ('bool', 'passthrough', BOOL_FEATURES),
    ])


def load_data():
    """
    Load and merge 4 synthetic tables into the analytical dataset.
    Mirrors the merge logic in 05_delay_risk_model.ipynb Cell 3 exactly.
    """
    required = ['prior_auth_requests.csv', 'providers.csv', 'members.csv', 'services.csv']
    for fname in required:
        fpath = os.path.join(DATA_DIR, fname)
        if not os.path.exists(fpath):
            print("ERROR: Required file not found: " + fpath)
            print("Run this script from the project root directory.")
            sys.exit(1)

    print("Loading tables from: " + DATA_DIR + "/")
    fa   = pd.read_csv(os.path.join(DATA_DIR, "prior_auth_requests.csv"))
    prov = pd.read_csv(os.path.join(DATA_DIR, "providers.csv"))
    memb = pd.read_csv(os.path.join(DATA_DIR, "members.csv"))
    svc  = pd.read_csv(os.path.join(DATA_DIR, "services.csv"))
    print("  prior_auth_requests: {:,} rows".format(len(fa)))

    # Merge provider, member, and service attributes
    df = fa.merge(
        prov[['provider_id', 'provider_type', 'network_status', 'provider_risk_segment',
              'avg_incomplete_submission_rate', 'avg_response_time_days', 'region']],
        on='provider_id', how='left'
    )
    df = df.merge(
        memb[['member_id', 'age_band', 'plan_type', 'risk_level',
              'chronic_condition_count', 'member_tenure_months']],
        on='member_id', how='left'
    )
    df = df.merge(
        svc[['service_id', 'service_category', 'procedure_group']],
        on='service_id', how='left'
    )
    print("  Merged dataset: {:,} rows x {} columns".format(df.shape[0], df.shape[1]))

    # Build targets
    # delayed_flag: 1 if decision_time_days > CMS-allowed SLA
    allowed = df['request_type'].map({'Standard': 7, 'Expedited': 3}).fillna(7)
    df['delayed_flag'] = (df['decision_time_days'] > allowed).astype(int)
    # denied_flag: 1 if initial decision = Denied (NOT final_outcome -- leakage exclusion)
    df['denied_flag'] = (df['decision'] == 'Denied').astype(int)

    print("  delayed_flag positive rate: {:.1%}".format(df['delayed_flag'].mean()))
    print("  denied_flag positive rate:  {:.1%}".format(df['denied_flag'].mean()))

    for col in BOOL_FEATURES:
        if df[col].dtype in (bool, object):
            df[col] = df[col].astype(int)

    X = df[ALL_FEATURES].copy()
    return X, df['delayed_flag'], df['denied_flag'], df


def train_delay_model(X, y_delay):
    print("\nTraining delay risk model (GradientBoostingClassifier)...")
    pipe = Pipeline([
        ('pre', build_preprocessor()),
        ('clf', GradientBoostingClassifier(**DELAY_PARAMS)),
    ])
    pipe.fit(X, y_delay)
    out_path = os.path.join(MODEL_DIR, "delay_model.pkl")
    with open(out_path, 'wb') as f:
        pickle.dump(pipe, f)
    print("  Saved: " + out_path)
    return pipe


def train_denial_model(X, y_denial):
    print("\nTraining denial risk model (LogisticRegression)...")
    pipe = Pipeline([
        ('pre', build_preprocessor()),
        ('clf', LogisticRegression(**DENIAL_PARAMS)),
    ])
    pipe.fit(X, y_denial)
    out_path = os.path.join(MODEL_DIR, "denial_model.pkl")
    with open(out_path, 'wb') as f:
        pickle.dump(pipe, f)
    print("  Saved: " + out_path)
    return pipe


def build_feature_metadata(delay_pipe, denial_pipe, X):
    # OHE expanded feature names from delay pipeline
    ohe = delay_pipe.named_steps['pre'].named_transformers_['cat']
    ohe_names = list(ohe.get_feature_names_out(CAT_FEATURES))
    expanded_names = ohe_names + NUM_FEATURES + BOOL_FEATURES

    # LR coefficients for denial explanation
    lr_clf = denial_pipe.named_steps['clf']
    ohe_d  = denial_pipe.named_steps['pre'].named_transformers_['cat']
    ohe_names_d = list(ohe_d.get_feature_names_out(CAT_FEATURES))
    exp_names_d = ohe_names_d + NUM_FEATURES + BOOL_FEATURES
    lr_coef = {name: float(coef) for name, coef in zip(exp_names_d, lr_clf.coef_[0])}

    # Dropdown values per categorical feature
    dropdowns = {col: sorted(X[col].dropna().unique().tolist()) for col in CAT_FEATURES}

    meta = {
        "cat_features":           CAT_FEATURES,
        "num_features":           NUM_FEATURES,
        "bool_features":          BOOL_FEATURES,
        "all_features":           ALL_FEATURES,
        "delay_threshold":        DELAY_THRESHOLD,
        "denial_threshold":       DENIAL_THRESHOLD,
        "delay_threshold_logic":  "GBM predict_proba >= 0.193 -> High delay risk (recall=0.75 on test split)",
        "denial_threshold_logic": "LR predict_proba >= 0.052 -> High denial risk (recall=0.70 on test split)",
        "dropout_values":         dropdowns,
        "expanded_feature_names": expanded_names,
        "denial_lr_coefficients": lr_coef,
        "notes": (
            "Models trained on full 25,000-row synthetic dataset. "
            "Thresholds from Phase 5 precision-recall analysis. "
            "Do not approve or deny care. Decision-support only."
        )
    }

    out_path = os.path.join(MODEL_DIR, "feature_metadata.json")
    with open(out_path, 'w') as f:
        json.dump(meta, f, indent=2, default=str)
    print("\n  Saved: " + out_path)
    return meta


def main():
    print("=" * 60)
    print("PAIS -- train_models.py")
    print("Prior Authorization Intelligence System | Phase 6")
    print("Synthetic data only. No PHI. No real payer records.")
    print("Models do not approve or deny care.")
    print("=" * 60)

    X, y_delay, y_denial, df = load_data()
    delay_pipe  = train_delay_model(X, y_delay)
    denial_pipe = train_denial_model(X, y_denial)
    build_feature_metadata(delay_pipe, denial_pipe, X)

    print("\n" + "=" * 60)
    print("Training complete. Files written to app/models/:")
    print("  delay_model.pkl       -- GBM delay risk pipeline")
    print("  denial_model.pkl      -- LR denial risk pipeline")
    print("  feature_metadata.json -- thresholds + LR coefficients + dropdowns")
    print("\nRun the app with:")
    print("  streamlit run app/streamlit_app.py")
    print("=" * 60)


if __name__ == "__main__":
    main()
