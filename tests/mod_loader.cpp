#include "loader/mods.h"
#include <filesystem>
#include <bit>
#include <cstdio>
#include <fstream>
#include <stdexcept>

#define CHECK(value) do { if (!(value)) throw std::runtime_error("Failed: " #value); } while (false)
static int errors = 0;
static void log_message(const char* message) {
    std::puts(message);
    if (std::string_view(message).starts_with("ERROR")) ++errors;
}
int main(int argc, char** argv) {
    try {
        CHECK(argc == 2);
        const auto dll = std::filesystem::absolute(argv[1]);
        HMODULE sdk = LoadLibraryExW((dll.parent_path() / "NimbyRailsFranceSDK.dll").c_str(), nullptr,
            LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32);
        CHECK(sdk);
        const auto root = dll.parent_path() / "loader-test" / "NRFMods";
        std::filesystem::create_directories(root / "sfr");
        std::filesystem::create_directories(root / "broken");
        const auto deployed = root / "sfr" / dll.filename();
        std::ofstream(root / "sfr" / "nrf-mod.ini") << "[NRFMod]\nlibrary=" << dll.filename().string() << '\n';
        std::ofstream(root / "broken" / "nrf-mod.ini") << "[NRFMod]\nlibrary=../outside.dll\n";
        std::filesystem::copy_file(dll, deployed, std::filesystem::copy_options::overwrite_existing);
        HMODULE handle = LoadLibraryExW(deployed.c_str(), nullptr, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32);
        CHECK(handle);
        using Status = DWORD (WINAPI*)(void*);
        auto status = std::bit_cast<Status>(GetProcAddress(handle, "NRFMod_IsInitializedV1"));
        auto start = std::bit_cast<Status>(GetProcAddress(handle, "NRFMod_StartV1"));
        using Show = DWORD (WINAPI*)(uint64_t, const char*);
        auto show = std::bit_cast<Show>(GetProcAddress(handle, "NRFMod_ShowTextureV1"));
        CHECK(show && show(1, "imgs/ca/sem_bal/tex00.svg") == 9);
        CHECK(status && start && status(nullptr) == 0); // No startup work under loader lock.
        CHECK(start(reinterpret_cast<void*>(1)) == 1 && status(nullptr) == 0);
        nimby::loader::Mods mods;
        mods.start(root.wstring(), log_message);
        CHECK(errors == 1 && status(nullptr) == 1); // A broken mod does not block SFR.
        CHECK(show(1, nullptr) == 1 && show(0, "imgs/ca/sem_bal/tex00.svg") == 1);
        CHECK(show(1, "imgs/ca/sem_bal/tex00.svg") == 3); // In-game SDK route refuses our non-game host.
        CHECK(start(nullptr) == 4);
        mods.start(root.wstring(), log_message);
        CHECK(errors == 1 && status(nullptr) == 1);
        CHECK(mods.stop(log_message) && status(nullptr) == 0);
        CHECK(mods.stop(log_message));
        mods.start(root.wstring(), log_message);
        CHECK(status(nullptr) == 1);
        CHECK(mods.stop(log_message) && status(nullptr) == 0);
        FreeLibrary(handle);
        std::puts("PASS: DLL discovery, explicit initialization, failure isolation, duplicate start, stop/restart");
        return 0;
    } catch (const std::exception& error) { std::fprintf(stderr, "%s\n", error.what()); return 1; }
}
