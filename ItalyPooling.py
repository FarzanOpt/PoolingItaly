"""
Created on Mon Oct 23 14:51:29 2017
@author: Farzaneh
"""
# main code
import matlab.engine
import io
import sys
import numpy as np
import scipy.io

class Algo:
    
     def start(self, mode,params):         
        self.params         = params
        self.MODE           = mode
        
        # find out if we are on the Alpiq platform or work locally
        try:        
            mimGet("Workflow", "Workflow Name") # this function is only available on the platform
            self.ONPLATFORM = True
        except:
            self.ONPLATFORM = False
        # starting MATLAB
        try:
            self.startMatlab()
        except Exception as e:
            # If there is a problem already at initialization, we stop immediately
            self.stop(e)
            print(e)
        
        return
    # MSD optimization (reserve)
     def optimizeMSD(self, msd, params):   
        
        try:
            ret = self.eng.main_MSD(msd, params) 
        except Exception as e:
            print(e)
            self.deinitialize() # make sure that the Matlab engine really quits
            try:
                # Try to start a new Matlab engine (only once so far)
                self.startMatlab()
                ret = self.eng.main_MSD(msd, params) 
            except Exception as e:
                self.stop(e) # If another error occurs, then we stop the pooling
             
        # print and reset string buffers to avoid increasing memory consumption
        print(self.out.getvalue())
        self.out.truncate(0)
        self.out.seek(0)
        print(self.err.getvalue())
        self.err.truncate(0)
        self.err.seek(0)
        
        
        # PV after MSV
        UnitName    = ret['UnitPVmsd'].keys()     
        Outcome_MW  = ret['UnitPVmsd'].values()
        N           = len(UnitName) # number of units
        ScheduleOut = ret['UnitPVmsd'].fromkeys(UnitName)

        TypePout = type(Outcome_MW[0])                

        TypeOutList  = TypePout is matlab.mlarray.double
        TypeOutFloat = TypePout is float
        if TypeOutList:
            for x in range(0,N):
                ScheduleOut[UnitName[x]] = Outcome_MW[x]._data.tolist()
        elif TypeOutFloat:
            for x in range(0,N):
                ScheduleOut[UnitName[x]] = Outcome_MW[x]
        # Flags
        FlagRampLim = []
        flagRampLim = ret['flag_rampLim'];
        FlagRampLim.append( flagRampLim._data.tolist() )
        
        FlagGenLim = []
        flagGenLim = ret['flag_genLim'];
        FlagGenLim.append( flagGenLim._data.tolist() )

        # solver flag
        MSD_Opt_status = []
        MSD_Opt_status.append(ret['MSDoptStatus']._data.tolist())

        # warning message
        Wrnng    = ret['wrnng']

        # error message
        Err = ret['err']
        
        MSDAlgoOutput = {'ScheduleOut': ScheduleOut,\
                      'FlagGenLim': FlagGenLim,\
                      'FlagRampLim': FlagRampLim,\
                      'MSD_Opt_status': MSD_Opt_status,\
                      'Wrnng': Wrnng,\
                      'Err': Err}
        return (MSDAlgoOutput) 
    
    # BDE optimization (activation)
     def optimizeBDE(self, BDE, params):      
        
        try:
            ret = self.eng.BDE_main(BDE['BDE_startTime'], BDE['BDE_endTime'], BDE['BDE_status'], BDE['BDE_Activation'], self.params)   
            
        except Exception as e:
            print(e)
            self.deinitialize() # make sure that the Matlab engine really quits
            try:
                # Try to start a new Matlab engine (only once so far)
                self.startMatlab()
                ret = self.eng.BDE_main(BDE['BDE_startTime'], BDE['BDE_endTime'], BDE['BDE_status'], BDE['BDE_Activation'], self.params) 
            except Exception as e:
                self.stop(e) # If another error occurs, then we stop the pooling
              
        # print and reset string buffers to avoid increasing memory consumption
        print(self.out.getvalue())
        self.out.truncate(0)
        self.out.seek(0)
        print(self.err.getvalue())
        self.err.truncate(0)
        self.err.seek(0)
        
#        # PVM
        UnitName    = ret['UnitPVM'].keys()     
        Outcome_MW  = ret['UnitPVM'].values()
        N           = len(UnitName) # number of units
        ScheduleOut = ret['UnitPVM'].fromkeys(UnitName)

        TypePout = type(Outcome_MW[0])                

        TypeOutList  = TypePout is matlab.mlarray.double
        TypeOutFloat = TypePout is float
        if TypeOutList:
            for x in range(0,N):
                ScheduleOut[UnitName[x]] = Outcome_MW[x]._data.tolist()
        elif TypeOutFloat:
            for x in range(0,N):
                ScheduleOut[UnitName[x]] = Outcome_MW[x]
             
        # Flags
        FlagRampLim = []
        flagRampLim = ret['flag_rampLim'];
        FlagRampLim.append( flagRampLim._data.tolist() )
        
        FlagGenLim = []
        flagGenLim = ret['flag_genLim'];
        FlagGenLim.append( flagGenLim._data.tolist() )

        # solver flag
        BDE_Opt_status = []
        BDE_Opt_status.append(ret['BDEoptStatus']._data.tolist())

        # warning message
        Wrnng    = ret['wrnng']

        # error message
        Err = ret['err']
        # hour and quarter for the start of activation
        StartTime = ret['startingQuarter'].values()
        
        StartH = StartTime[0]
        StartQ = StartTime[1]
        
        BDEAlgoOutput = {'PVM': ScheduleOut,\
                      'BDE_FlagGenLim': FlagGenLim,\
                      'BDE_FlagRampLim': FlagRampLim,\
                      'BDE_Opt_status': BDE_Opt_status,\
                      'BDE_Wrnng': Wrnng,\
                      'BDE_Err': Err,\
                      'start_hour' : StartH ,\
                      'start_quarter': StartQ }
        return (BDEAlgoOutput) 
   
     def startMatlab(self):      
        
        # Determine if JVM should be started with Matlab engine
        opts = ''
        if (self.MODE == 'live'):
            opts = '-nojvm' # see https://ch.mathworks.com/help/matlab/matlab_env/commonly-used-startup-options.html
    
        self.eng = matlab.engine.start_matlab(opts)
        self.out = io.StringIO()
        self.err = io.StringIO()
    
        # Make sure that yalmip, qpoases, etc is found
        try:
            if not(self.ONPLATFORM): 
                print('Dude, we are not Live')
                
            else: # relevant on Alpiq platform
                self.eng.addpath('/home/usr_vss01/development/tbxmanager',\
                                 nargout=0, stdout=self.out, stderr=self.err)
                self.eng.addpath('/home/usr_vss01/MATLAB/R2016b/toolbox/matlab/optimfun',\
                                 nargout=0, stdout=self.out, stderr=self.err)                
                self.eng.eval('tbxmanager restorepath', nargout=0, \
                          stdout=self.out, stderr=self.err)
        except Exception as e:
                print(e)
        
        return
    
     def stop(self, exception):
        print(exception)
          
        if not(self.ONPLATFORM):
            self.deinitialize()
            sys.exit("Pooling stopped due to exception.")
        else:
            raise exception # leads to default abort handling on platform            
        return
    
     def deinitialize(self):    
        try:
            self.eng.quit() # terminate Matlab engine
        except Exception as e:
            print(e)
    
        # print and close string buffers
        try:
            print(self.out.getvalue())
            self.out.close()
            print(self.err.getvalue())
            self.err.close()
        except Exception as e:
            print(e)        
        return       
         
