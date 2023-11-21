#include <jsi/jsilib.h>
#include <ReactCommon/CallInvoker.h>

namespace ops2 {
    namespace jsi = facebook::jsi;
    namespace react = facebook::react;

    void install(jsi::Runtime &rt,
                 std::function<void(const char *, const char *, bool)> setFn,
                 std::function<std::string(const char *, bool)> getFn,
                 std::function<void(const char *, bool)> delFn);
}

