import sys
import os
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

def process_data(file_path, output_dir):
    # Load Excel file
    df = pd.read_excel(file_path)

    # Convert 'Timestamp' to datetime
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    df.set_index('Timestamp', inplace=True)

    # Handle missing values
    df[['RI_Supplier1', 'RI_Distributor1', 'RI_Manufacturer1', 'RI_Retailer1', 'Total_Cost']] = \
        df[['RI_Supplier1', 'RI_Distributor1', 'RI_Manufacturer1', 'RI_Retailer1', 'Total_Cost']].interpolate()

    df['RI_Distributor1'].fillna(df['RI_Distributor1'].mean(), inplace=True)

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # **1. Generate Risk Index Trends Plot**
    trend_plot_path = os.path.join(output_dir, "trend_plot.png")
    plt.figure(figsize=(12,6))
    plt.plot(df['RI_Supplier1'], label='Supplier')
    plt.plot(df['RI_Distributor1'], label='Distributor')
    plt.plot(df['RI_Manufacturer1'], label='Manufacturer')
    plt.plot(df['RI_Retailer1'], label='Retailer')
    plt.xlabel('Time')
    plt.ylabel('Risk Index')
    plt.title('Risk Index Trends Over Time')
    plt.legend()
    plt.savefig(trend_plot_path, bbox_inches='tight', dpi=300)
    plt.close()

    # **2. Generate Correlation Heatmap**
    correlation_matrix = df.corr()
    heatmap_path = os.path.join(output_dir, "heatmap.png")
    plt.figure(figsize=(10,6))
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', fmt=".2f", linewidths=0.5)
    plt.title("Feature Correlation Heatmap")
    plt.savefig(heatmap_path, bbox_inches='tight', dpi=300)
    plt.close()

    # **3. Train ML Model**
    selected_features = ['Total_Cost', 'RI_Supplier1', 'RI_Retailer1', 'RI_Manufacturer1', 'RI_Distributor1']
    target_variable = 'SCMstability_category'

    if target_variable not in df.columns:
        raise ValueError(f"Target variable '{target_variable}' not found in the dataset.")

    X = df[selected_features]
    y = df[target_variable]

    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train model
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    # Predictions
    y_pred = model.predict(X_test)

    # Accuracy and classification report
    accuracy = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, output_dict=True)

    # **4. Save feature importance plot**
    feature_importance_path = os.path.join(output_dir, "feature_importance.png")
    feature_importance = model.feature_importances_
    plt.figure(figsize=(8, 5))
    sns.barplot(x=feature_importance, y=selected_features)
    plt.xlabel("Feature Importance Score")
    plt.ylabel("Features")
    plt.title("Feature Importance for SCM Stability Prediction")
    plt.savefig(feature_importance_path, bbox_inches='tight', dpi=300)
    plt.close()

    # **5. Return JSON Output**
    output = {
        "accuracy": accuracy,
        "classification_report": report,
        "trend_plot": trend_plot_path,
        "heatmap": heatmap_path,
        "feature_importance_plot": feature_importance_path
    }

    print(json.dumps(output))  # Ensures JSON output for Rails

if __name__ == "__main__":
    file_path = sys.argv[1]  # Input Excel file path
    output_dir = sys.argv[2]  # Directory to save plots
    process_data(file_path, output_dir)
