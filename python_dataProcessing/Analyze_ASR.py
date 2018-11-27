import pandas as pd
import numpy as np
import easygui as eg
import seaborn as sns
import matplotlib as plt

# Choose data file to open
data_file = eg.fileopenbox('Choose csv datafile',filetypes=['.txt','.m'])
datMat = pd.read_csv(data_file,header=None)
header= {0:'Chamber',1:'Subject',2:'Session',3:'Channel',4:'Trial',5:'Trial Num',6:'Group',7:'Param',8:'Trial List Block',9:'Samples',10:'Rate',11:'V Start',12:'mV Max',13:'T Max',14:'mv Avg',15:'V Peak',16:'T Peak',17:'Run Time',18:'TimeStamp',19:'Run Data'}
datMat = datMat.rename(columns=header)

