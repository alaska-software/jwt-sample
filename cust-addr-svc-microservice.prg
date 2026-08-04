//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// CustAddrSvc microservice: lifecycle hooks (beforeRun/afterRun,
/// onRestart/onRecover/onReady). Endpoints are bound in
/// custaddrsvc.exe.config.
/// </summary>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////
#include "common.ch"

CLASS CustAddrSvc FROM Microservice
   EXPORTED:
      CLASS METHOD beforeRun()
      CLASS METHOD afterRun()

      CLASS METHOD onRestart()
      CLASS METHOD onRecover()
      CLASS METHOD onReady()
ENDCLASS


CLASS METHOD CustAddrSvc:beforeRun(aParameters)
   // $TODO add your code here which you want to be executed before your service starts
RETURN SUPER:beforeRun(aParameters)


CLASS METHOD CustAddrSvc:afterRun()
   // $TODO add your code here
RETURN SUPER:afterRun()


CLASS METHOD CustAddrSvc:onRestart(oState)
   UNUSED(oState)
   XppFileLogger():warning(FormatMessage("Processing restart for(%1)",::classname()))

   // $TODO add your code here
RETURN SELF


CLASS METHOD CustAddrSvc:onRecover(oState)
   UNUSED(oState)
   XppFileLogger():warning(FormatMessage("Processing recover for(%1)",::classname()))

   /// add your code which is a last resort. repeated restarts failed
RETURN SELF

CLASS METHOD CustAddrSvc:onReady()
   /// $TODO add your code here
RETURN SELF
