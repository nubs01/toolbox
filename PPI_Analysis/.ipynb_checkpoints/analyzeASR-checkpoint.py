import sys
import os
import pandas as pd
import numpy as np
import matplotlib as plt
import seaborn as sns
import warnings

# Turn off annoying known warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
pd.options.mode.chained_assignment = None

def calcPPI(row):
   # print(row)
    if row['Trial_Type']=='PPI':
        stimDB = row['Stim_dB']
        stimMean = ppiData.query('Trial_Type=="Startle" & Stim_dB==@stimDB')['mV Max'].mean()
        return 100*(1-row['mV Max']/stimMean)
    else:
        return row['% PPI']
    
def get_ppi_metrics(x):
    d = {}
    d['Mean Startle (mV)'] = x['mV Max'].mean()
    d['Startle SD (mV)'] = x['mV Max'].std()
    d['Mean PPI (%)'] = x['% PPI'].mean()
    d['PPI SD (%)'] = x['% PPI'].std()
    return pd.Series(d,index=['Mean Startle (mV)',
                              'Startle SD (mV)','Mean PPI (%)',
                              'PPI SD (%)'])
    
custom_style = {'figure.facecolor':'.8',
                "axes.facecolor":".8",
                'axes.edgecolor':'.8',
                "axes.labelcolor":"black",
                "axes.grid":True,
                'grid.color':'black',
                "text.color":"black",
                "patch_edgecolor":'black',
                "xtick.color":"black",
                "ytick.color":"black",
                'axes.edgecolor':'black'}
sns.set_style('whitegrid',rc=custom_style)
sns.set_context('talk')
col_palette = sns.color_palette("bright")

file_paths = sys.argv[1:]

header= {0:'Chamber',1:'Subject',2:'Session',
         3:'Channel',4:'Trial',5:'Trial Num',
         6:'Group',7:'Param',8:'Trial List Block',
         9:'Samples',10:'Rate',11:'V Start',12:'mV Max',
         13:'T Max',14:'mv Avg',15:'V Peak',16:'T Peak',
         17:'Run Time',18:'TimeStamp',19:'Run Data'}

for fn in file_paths:
    data = pd.read_csv(fn,header=None)
    data = data.rename(columns=header)
    data = data.drop(columns=['Param','Run Data'])
    data = data.dropna()
    data_dir = os.path.split(fn)[0]
    
    # Parse Session and Trial 
    # into Date, Animal, Session_Type, Trial_Type, Stim DB, Prepulse DB
    data = pd.concat((data,data.Session.str.split('_', expand=True)),
                     axis=1).rename(columns={0:'Date',1:'Animal',
                                             2:'Session_Type'})
    data = pd.concat((data,data.Trial.str.split('_',expand=True)),
                     axis=1).rename(columns={0:'Trial_Type',1:'Stim_dB',
                                             2:'Prepulse_dB'})
    cols = ['Stim_dB','Prepulse_dB']
    data[cols] = data[cols].apply(pd.to_numeric)
    
    # Print info about data
    animal = data['Subject'].unique()
    if len(animal)>1:
        sys.exit('Multiple Animals found in database.') 
    else:
        animal = animal[0]
        
    trial_counts = data.groupby(['Session_Type',
                                'Trial_Type','Stim_dB',
                                 'Prepulse_dB']).size()
    print('Loaded data for '+animal)
    print('')
    print('')
    print('Trial Counts')
    print('---------------')
    trial_counts = trial_counts.to_frame().rename(columns={0:'Counts'})
    print(trial_counts)
    
    # Grab ASR and PPI Data
    asrData = data.query('Session_Type=="ASR"')
    ppiData = data.query('Session_Type=="rPPI"')
    
    # Calculate PPI 
    startleDB = ppiData.query('Trial_Type=="Startle"')['Stim_dB'].unique()
    ppiData["% PPI"] = np.nan
    ppiData['% PPI'] = ppiData.apply(calcPPI,axis=1)
    
    # Make and print table 
    
    ppi_metrics = ppiData.groupby(['Trial_Type',
                                   'Stim_dB',
                                   'Prepulse_dB']).apply(get_ppi_metrics).round(2)
    print ('')
    print('')
    print('PPI Metrics (from rPPI Session)')
    print('------------')
    print(ppi_metrics)
    
    # Make Figures
    pal = sns.color_palette('bright')
    plt.rcParams["figure.figsize"] = (30, 20)
    plt.rcParams["xtick.labelsize"] = 12
    
    # ASR Plot
    ax = plt.pyplot.subplot(2,1,1)
    g = sns.pointplot(ax=ax,x="Stim_dB",y='mV Max',
                      data=asrData,color='mediumvioletred',ci='sd')
    g.set_title(animal+' Acoustic Startle Response')
    g.set(xlabel='Stimulus dB',ylabel='Max Startle (mV)')

    # Raw PPI Startle Amplitudes
    ax = plt.pyplot.subplot(2,2,3)
    g = sns.barplot(ax=ax,x='Trial',y='mV Max',
                    data=ppiData,palette='bright')
    g.set_title(animal+' rPPI Startle Responses')
    g.set(xlabel='Stimulus dB',ylabel='Max Startle (mV)')

    # % PPI plot
    ax=plt.pyplot.subplot(2,2,4)
    g=sns.barplot(ax = ax,x='Prepulse_dB',y="% PPI",
                  data=ppiData,order = [70,75,80],palette=pal[3:6])
    g.set_title(animal+' Percent PPI')
    g.set(xlabel='Prepulse dB',ylabel='% PPI')

    savefile = os.path.join(data_dir,animal+'_PPI_Results_Figure.png')
    plt.pyplot.savefig(savefile)
    
    print('')
    print('Plot saved to '+savefile)
    print('Done!')