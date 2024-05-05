# Conductivity (S*m-1) to Salinity (ppt) Calculator
# Reference: https://reefapp.net/en/salinity-calculator
# Code from: http://www.code10.info/index.php%3Foption%3Dcom_content%26view%3Darticle%26id%3D65:conversion-between-conductivity-and-pss-78-salinity%26catid%3D54:cat_coding_algorithms_seawater%26Itemid%3D79

import math

def SAL(XR, XT):
    # PRACTICAL SALINITY SCALE 1978 DEFINITION WITH TEMPERATURE CORRECTION;XT :=T-15.0; XR:=SQRT(RT)
    return ((((2.7081*XR-7.0261)*XR+14.0941)*XR+25.3851)*XR - 0.1692)*XR+0.0080 + (XT/(1.0+0.0162*XT))*(((((-0.0144*XR + 0.0636)*XR-0.0375)*XR-0.0066)*XR-0.0056)*XR+0.0005)

def RT35(XT):
    # FUNCTION RT35: C(35,T,0)/C(35,15,0) VARIATION WITH TEMPERATURE
    return (((1.0031E-9 * XT - 6.9698E-7) * XT + 1.104259E-4) * XT + 2.00564E-2) * XT + 0.6766097

def C(XP):
    #  C(XP) POLYNOMIAL CORRESPONDS TO A1-A3 CONSTANTS: LEWIS 1980
    return ((3.989E-15 * XP - 6.370E-10) * XP + 2.070E-5) * XP

def B(XT):
    return (4.464E-4 * XT + 3.426E-2) * XT + 1.0

def A(XT):
    # A(XT) POLYNOMIAL CORRESPONDS TO B3 AND B4 CONSTANTS: LEWIS 1980 Begin
    return -3.107E-3 * XT + 0.4215

def Cond2Sal78(aConductivity: float, Temp: float, Press: float):
    # Function Cond2Sal converts a conductivity value of seawater to a value of the pratical-salinity-scale 1978 (PSS-78) for given values of conductivity, temperature and pressure. Result is returned as parameter in aSalinity. A returned boolean result TRUE of the function indicates that the result is reliable.
    # UNITS:
    # PRESSURE      Press          DECIBARS
    # TEMPERATURE   Temp           DEG CELSIUS IPTS-68
    # CONDUCTIVITY  aConductivity  S/m (1 siemens/meter [S/m] = 10 millisiemens/centimeter [mS/cm])
    # SALINITY      aSalinity      PSS-78
    # ----------------------------------------------------------
    # CHECKVALUES:
    # 2.) aSalinity=40.00000 for CND=1.888091, T=40 DEG C, P=10000 DECIBARS
    # -------------------------------------------------------
    # SAL78 RATIO: RETURNS ZERO FOR CONDUCTIVITY RATIO: < 0.0005
    # ----------------------------------------------------------
    # This source code is based on the original fortran code in: UNESCO technical papers in marine science 44 (1983) - 'Algorithms for computation of fundamental properties of seawater'

    

    Cond2Sal78 = True
    aSalinity = 0

    if aConductivity <= 0.2:
        Cond2Sal78 = False
        return

    DT = Temp - 15
    aSalinity = aConductivity/4.2914
    RT = aSalinity / (RT35 (Temp) * (1.0 + C (Press) / (B (Temp) + A (Temp) * aSalinity)))
    RT = math.sqrt(abs(RT))
    aSalinity = SAL(RT, DT)

    return aSalinity

if __name__ == "__main__":
    import os
    import sys
    import pandas as pd
    import numpy as np

    os.chdir("C:\\Users\\wcf\\Desktop\\DMB\\CRF marineGEO mesocosm\\")
    filename = "mesocosm_temp_salinity_20230718.xlsx"
    sheet_list = ["L01", "L06", "L08", "L10"]

    for sheet in sheet_list:
        df = pd.read_excel(filename, sheet_name=sheet)
        print(df.iloc[:, 4]) # Temperature raw value
        print(df.iloc[:, 6]) # Salinity (Conductivity) raw value

        salinity_list = []
        for i in range(df.shape[0]):
            if np.isnan(df.iloc[i, 6]):
                salinity_list.append("")
                pass
            else:
                conductivity = float(df.iloc[i, 6])*0.1 # change unit from mS/cm (unit output of Odyssey loggers) to S/m
                temperature = float(df.iloc[i, 4])
                salinity = Cond2Sal78(conductivity, temperature, 0)
                salinity_list.append(salinity)
    
        df["Salinity (ppt)"] = salinity_list

        target_file = "Cond2Sal78_py_output.xlsx"
        if os.path.isfile(target_file):
            with pd.ExcelWriter(target_file, mode="a") as writer: 
                df.to_excel(writer, sheet_name=sheet, header=False, index=False)
        else:
            with pd.ExcelWriter(target_file) as writer:
                df.to_excel(writer, sheet_name=sheet, header=False, index=False)
 
