import pandas as pd
import numpy as np
import easygui as eg
import seaborn as sns
import matplotlib as plt
from scipy.optimize import curve_fit
import os

# Open data file
data_file = eg.fileopenbox('Choose csv datafile',filetypes=['.txt','.m'])
data_dir = os.path.dirname(data_file)
datMat = pd.read_csv(data_file,header=None)
header= {0:'Chamber',1:'Subject',2:'Session_ID',3:'Channel',4:'Trial_ID',5:'Trial Num',6:'Group',7:'Param',8:'Trial List Block',9:'Samples',10:'Rate',11:'V Start',12:'mV Max',13:'T Max',14:'mv Avg',15:'V Peak',16:'T Peak',17:'Run Time',18:'TimeStamp',19:'Run Data'}
datMat = datMat.rename(columns=header)

# Figure out animal
animals = datMat['Subject'].unique()
if len(animals)>1:
    anim = eg.choicebox('Choose animal to analyze:','Animal Selection',animals)
    if anim is None:
        return 0
else:
    anim = animals[0]
df = df.query('Subject=="'+anim+'"')

# Parse session ID into date, anim, and session type
new = data['Session_ID'].str.split('_')
df['Date'] = new[0]
df['Session'] = new[2]

# Parse TrialID into Trial, StimDB, PrepulseDB
new = df['Trial_ID'].str.split('_')
df['Trial'] = new[0]
df['StimDB'] = new[1]
df['PrepulseDB'] = new[2]

# For ASR session plot Startle trial stim dB vs max startle response
df = df.query('Session=="ASR" and Trial=="Startle"')
g = sns.regplot(data=df,x='StimDB',y='mv Max',x_estimator=np.mean,logx=True,truncate=True)

def fit_func(x, a, b,c):
    return a*np.log2(c+x)+b

fit_params, pcov = curve_fit(fit_func,df['StimDB'],df['mv Max'])

# figure out optimal volume and return, save plot with optimal volume line
