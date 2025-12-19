import pandas as pd

def optimize_care_schedules(data_path, pss_target):
    df = pd.read_csv(data_path)
    current_pss = df['SatisfactionScore'].mean()
    
    if current_pss >= pss_target:
        return "Patient Satisfaction Score meets target."
    
    # Example adjustment (reduce resources for less affluent patients)
    df.loc[df['Priority'] == 'Low', 'ResourceRequirement'] -= 1
    df.loc[df['Priority'] == 'High', 'ResourceRequirement'] += 1
    
    new_pss = df['SatisfactionScore'].mean()
    return f"Adjusted resource allocation. New Patient Satisfaction Score: {new_pss}"

if __name__ == "__main__":
    data_path = "patient_data"
    pss_target = 90
    result = optimize_care_schedules(data_path, pss_target)
    print(result)
