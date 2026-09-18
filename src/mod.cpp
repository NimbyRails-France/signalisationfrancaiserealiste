#include <nimby/mod.hpp>

nimby::Mod nimby::createMod() {
    return {
        .showTexture = [](Id signal, const char* path) {
            SignalTextures::inGame().show(signal, {"sfr_bal_a_cpp_v1", path});
        },
        .restoreTexture = [](Id signal) {
            SignalTextures::inGame().restore(signal);
        }
    };
}
