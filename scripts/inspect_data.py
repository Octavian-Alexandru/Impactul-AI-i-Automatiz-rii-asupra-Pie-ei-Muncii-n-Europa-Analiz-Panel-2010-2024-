
import pandas as pd
file_path = "data/raw/desi_ai.csv.xlsx"
try:
    if "Sheet 9" in pd.ExcelFile(file_path).sheet_names:
        df = pd.read_excel(file_path, sheet_name="Sheet 9", header=None)
        print("Sheet 9 head:")
        print(df.iloc[0:15])
    else: 
        print("Sheet 9 not found")
except Exception as e:
    print("Error:", e)
