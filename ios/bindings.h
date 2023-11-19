#include <jsi/jsilib.h>
#include <jsi/jsi.h>
#include <ReactCommon/CallInvoker.h>

using namespace facebook;

namespace opsecurestorage {

void install(jsi::Runtime &rt, std::shared_ptr<react::CallInvoker> jsCallInvoker);
void clearState();

}

