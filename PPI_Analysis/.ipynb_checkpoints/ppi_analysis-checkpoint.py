import pandas as pd
import numpy as np


# Function to read in txt database file to pandas dataframe
def import_ppi_data(data_file):
    import pandas as pd
    header= {0:'Chamber',1:'Subject',2:'Session',
             3:'Channel',4:'Trial',5:'Trial Num',
             6:'Group',7:'Param',8:'Trial List Block',
             9:'Samples',10:'Rate',11:'V Start',12:'mV Max',
             13:'T Max',14:'mv Avg',15:'V Peak',16:'T Peak',
             17:'Run Time',18:'TimeStamp',19:'Run Data'}
    data = pd.read_csv(data_file,header=None)
    data = data.rename(columns=header)
    
    # Drop columns filled with NaNs (remove this line if you start using these columns)
    data = data.drop(columns=['Param','Run Data'])    
    
    return data

# Function to parse Session and Trial columns to get Date, Animal, Session_Type, Stim_dB, and Prepulse_dB, 
def parse_session_and_trial(data):
    data = pd.concat((data,data.Session.str.split('_', expand=True)),
                     axis=1).rename(columns={0:'Date',1:'Animal',2:'Session_Type'})
    data = pd.concat((data,data.Trial.str.split('_',expand=True)),
                     axis=1).rename(columns={0:'Trial_Type',1:'Stim_dB',2:'Prepulse_dB'})
    cols = ['Stim_dB','Prepulse_dB']
    data[cols] = data[cols].apply(pd.to_numeric)
    return data

def calcPPI(row,data):
   # print(row)
    if row['Trial_Type']=='PPI':
        stimDB = row['Stim_dB']
        stimMean = data.query('Trial_Type=="Startle" & Stim_dB==@stimDB')['mV Max'].mean()
        return 100*(1-row['mV Max']/stimMean)
    else:
        return row['% PPI']

def make_ppi_column(data):
    data['% PPI'] = np.nan
    data['% PPI'] = data.apply(lambda x: calcPPI(x,data),axis=1)
    
