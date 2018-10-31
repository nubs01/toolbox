import numpy as np
import pandas as pd

def bootstrap(data,n_boot=1000,bootfun=np.mean):
    stats = []
    N = len(data)
    for i in range(n_boot):
        stats.append(bootfun(np.random.choice(data,N,replace=True)))
    sem = np.std(stats)
    mean = np.mean(stats)
    ci = (np.percentile(stats,2.5),np.percentile(stats,97.5))
    return mean, sem, ci
    
def permutation_test(pooled,n,m,delta,myfun=lambda x,y:np.mean(x)-np.mean(y),n_boot=1000):
    N = n+m
    stats = []
    for i in range(n_boot):
        np.random.shuffle(pooled)
        stats.append(myfun(pooled[:n],pooled[n:]))
    stats = np.array(stats)
    diffCount = (np.abs(stats)>=delta).sum()
    pval = 1 - (float(diffCount)/float(n_boot))
    return pval