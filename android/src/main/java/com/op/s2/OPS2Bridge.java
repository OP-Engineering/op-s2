package com.op.s2;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.turbomodule.core.CallInvokerHolderImpl;

public class OPS2Bridge {
  private native void installNativeJsi(long jsContextNativePointer, CallInvokerHolderImpl jsCallInvokerHolder);
  public static final OPS2Bridge instance = new OPS2Bridge();

  public void install(ReactContext context) {
    long jsContextPointer = context.getJavaScriptContextHolder().get();
    CallInvokerHolderImpl jsCallInvokerHolder = (CallInvokerHolderImpl)context.getCatalystInstance().getJSCallInvokerHolder();
    installNativeJsi(
      jsContextPointer,
      jsCallInvokerHolder
    );
  }
}
