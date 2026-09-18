#pragma once
#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string_view>
#include <windows.h>

namespace sfr {
inline constexpr std::array<std::string_view, 11> bal_a_files{
    "tex00.svg", "tex01.svg", "tex02.svg", "tex03.svg", "tex04.svg",
    "tex05.svg", "tex06.svg", "tex07.svg", "tex08.svg", "tex10.svg", "xx.svg"
};

inline void check_test_textures() {
    std::wstring executable(32768, L'\0');
    const auto length = GetModuleFileNameW(nullptr, executable.data(), static_cast<DWORD>(executable.size()));
    if (!length || length >= executable.size()) throw std::runtime_error("Cannot locate executable");
    executable.resize(length);
    const auto folder = std::filesystem::path(executable).parent_path()/"imgs/ca/sem_bal";
    for (const auto name : bal_a_files) {
        const auto path = folder/name;
        std::ifstream file(path, std::ios::binary);
        if (!file) throw std::runtime_error("Missing BAL A texture: " + std::string(name));
        const std::string svg{std::istreambuf_iterator<char>{file}, {}};
        if (svg.find("<svg") == std::string::npos) throw std::runtime_error("Invalid SVG: " + std::string(name));
        std::cout << name << " | " << svg.size() << " bytes\n";
    }
    std::cout << "BAL semaphore type A: 11 test textures available; aspect mapping not assigned.\n";
}
}
