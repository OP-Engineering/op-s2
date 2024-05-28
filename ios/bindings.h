#include <ReactCommon/CallInvoker.h>
#include <jsi/jsilib.h>

namespace ops2 {
namespace react = facebook::react;
namespace jsi = facebook::jsi;

void install(jsi::Runtime &rt,
             std::shared_ptr<react::CallInvoker> jsCallInvoker);
void clearState();
} // namespace ops2
