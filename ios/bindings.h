#include <jsi/jsilib.h>
#include <ReactCommon/CallInvoker.h>

namespace ops2 {
    using namespace facebook;

    void install(jsi::Runtime &rt, std::shared_ptr<react::CallInvoker> jsCallInvoker);
    void clearState();
}

