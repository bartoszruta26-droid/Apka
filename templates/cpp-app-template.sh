#!/bin/bash

#===============================================================================
# Szablon projektu: Aplikacja C++ z GUI (GTK/Qt)
# Template: C++ Application with GUI
#===============================================================================

set -euo pipefail

PROJECT_NAME="${1:-my-cpp-app}"
PROJECT_DIR="${2:-./${PROJECT_NAME}}"
GUI_TYPE="${3:-gtk}"  # gtk, qt, or console

echo "🔧 Tworzenie projektu C++: $PROJECT_NAME"
echo "Typ GUI: $GUI_TYPE"
echo "Lokalizacja: $PROJECT_DIR"

# Tworzenie struktury katalogów
mkdir -p "$PROJECT_DIR"/{src,include,tests,resources,docs,build}

# src/main.cpp
cat > "$PROJECT_DIR/src/main.cpp" << 'EOF'
/**
 * @file main.cpp
 * @brief Main entry point for the C++ application
 */

#include <iostream>
#include <string>
#include <memory>

#ifdef USE_GTK
#include <gtk/gtk.h>
#elif defined(USE_QT)
#include <QApplication>
#include <QMainWindow>
#endif

#include "application.hpp"

int main(int argc, char* argv[]) {
    std::cout << "Starting " << APP_NAME << " v" << APP_VERSION << std::endl;
    
#ifdef USE_GTK
    // Initialize GTK
    gtk_init(&argc, &argv);
    
    // Create and show main window
    GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), APP_NAME);
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    
    gtk_widget_show_all(window);
    
    gtk_main();
    
#elif defined(USE_QT)
    QApplication app(argc, argv);
    
    QMainWindow window;
    window.setWindowTitle(APP_NAME);
    window.resize(800, 600);
    window.show();
    
    return app.exec();
    
#else
    // Console mode
    std::cout << "Running in console mode..." << std::endl;
    
    Application app;
    return app.run();
#endif
    
    return 0;
}
EOF

# include/application.hpp
cat > "$PROJECT_DIR/include/application.hpp" << 'EOF'
/**
 * @file application.hpp
 * @brief Main application class header
 */

#ifndef APPLICATION_HPP
#define APPLICATION_HPP

#include <string>
#include <vector>
#include <memory>

#define APP_NAME "MyCppApp"
#define APP_VERSION "1.0.0"

/**
 * @class Application
 * @brief Main application class managing the program lifecycle
 */
class Application {
public:
    /**
     * @brief Construct a new Application object
     */
    Application();
    
    /**
     * @brief Destroy the Application object
     */
    ~Application();
    
    /**
     * @brief Run the main application loop
     * @return int Exit code
     */
    int run();
    
    /**
     * @brief Initialize application components
     * @return true if initialization successful
     */
    bool initialize();
    
    /**
     * @brief Cleanup application resources
     */
    void cleanup();

private:
    bool m_initialized;
    std::string m_configPath;
};

#endif // APPLICATION_HPP
EOF

# src/application.cpp
cat > "$PROJECT_DIR/src/application.cpp" << 'EOF'
/**
 * @file application.cpp
 * @brief Main application class implementation
 */

#include "application.hpp"
#include <iostream>

Application::Application() : m_initialized(false), m_configPath("config.json") {
    std::cout << "Application constructor called" << std::endl;
}

Application::~Application() {
    std::cout << "Application destructor called" << std::endl;
    cleanup();
}

bool Application::initialize() {
    std::cout << "Initializing application..." << std::endl;
    
    // Load configuration
    // Initialize subsystems
    // Setup logging
    
    m_initialized = true;
    return m_initialized;
}

void Application::cleanup() {
    std::cout << "Cleaning up resources..." << std::endl;
    
    // Save state
    // Release resources
    // Close connections
    
    m_initialized = false;
}

int Application::run() {
    if (!initialize()) {
        std::cerr << "Failed to initialize application" << std::endl;
        return 1;
    }
    
    std::cout << "Application running..." << std::endl;
    
    // Main application loop
    // Process events
    // Update state
    // Render
    
    std::cout << "Enter 'quit' to exit: ";
    std::string input;
    while (std::cin >> input && input != "quit") {
        std::cout << "Command: " << input << std::endl;
        std::cout << "Enter 'quit' to exit: ";
    }
    
    cleanup();
    std::cout << "Application exited successfully" << std::endl;
    return 0;
}
EOF

# tests/test_application.cpp
cat > "$PROJECT_DIR/tests/test_application.cpp" << 'EOF'
/**
 * @file test_application.cpp
 * @brief Unit tests for Application class
 */

#include <iostream>
#include <cassert>
#include "../include/application.hpp"

void test_application_creation() {
    std::cout << "Test: Application creation... ";
    Application app;
    std::cout << "PASSED" << std::endl;
}

void test_application_run() {
    std::cout << "Test: Application run (mock)... ";
    // Note: Full run test would require mocking stdin
    std::cout << "SKIPPED (requires interactive input)" << std::endl;
}

void test_version_macros() {
    std::cout << "Test: Version macros... ";
    assert(std::string(APP_NAME) == "MyCppApp");
    assert(std::string(APP_VERSION) == "1.0.0");
    std::cout << "PASSED" << std::endl;
}

int main() {
    std::cout << "=== Running Unit Tests ===" << std::endl;
    std::cout << std::endl;
    
    test_application_creation();
    test_version_macros();
    test_application_run();
    
    std::cout << std::endl;
    std::cout << "=== All Tests Complete ===" << std::endl;
    
    return 0;
}
EOF

# CMakeLists.txt
cat > "$PROJECT_DIR/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(MyCppApp VERSION 1.0.0 LANGUAGES CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build options
option(USE_GTK "Build with GTK GUI" OFF)
option(USE_QT "Build with Qt GUI" OFF)
option(BUILD_TESTS "Build unit tests" ON)
option(BUILD_DOCS "Build documentation" OFF)

# Compiler flags
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Include directories
include_directories(${PROJECT_SOURCE_DIR}/include)

# Main executable
add_executable(${PROJECT_NAME}
    src/main.cpp
    src/application.cpp
)

# Link libraries based on GUI type
if(USE_GTK)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USE_GTK)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
    target_include_directories(${PROJECT_NAME} PRIVATE ${GTK3_INCLUDE_DIRS})
    target_link_libraries(${PROJECT_NAME} ${GTK3_LIBRARIES})
elseif(USE_QT)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USE_QT)
    find_package(Qt5 COMPONENTS Widgets REQUIRED)
    target_link_libraries(${PROJECT_NAME} Qt5::Widgets)
endif()

# Tests
if(BUILD_TESTS)
    enable_testing()
    
    add_executable(test_app
        tests/test_application.cpp
        src/application.cpp
    )
    
    add_test(NAME ApplicationTests COMMAND test_app)
endif()

# Installation
install(TARGETS ${PROJECT_NAME} DESTINATION bin)
install(DIRECTORY include/ DESTINATION include)

# Documentation
if(BUILD_DOCS)
    find_package(Doxygen QUIET)
    if(DOXYGEN_FOUND)
        set(DOXYGEN_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/docs)
        doxygen_add_docs(docs ALL ${PROJECT_SOURCE_DIR}/include)
    endif()
endif()
EOF

# Makefile (alternative to CMake)
cat > "$PROJECT_DIR/Makefile" << 'EOF'
# Makefile for MyCppApp

CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -Wpedantic -I./include
LDFLAGS = 
DEBUG_FLAGS = -g -DDEBUG
RELEASE_FLAGS = -O3 -DNDEBUG

SRCDIR = src
INCDIR = include
TESTDIR = tests
BUILDDIR = build

SOURCES = $(SRCDIR)/main.cpp $(SRCDIR)/application.cpp
OBJECTS = $(BUILDDIR)/main.o $(BUILDDIR)/application.o
TARGET = my-cpp-app

TEST_SOURCES = $(TESTDIR)/test_application.cpp $(SRCDIR)/application.cpp
TEST_TARGET = test_app

.PHONY: all clean debug release test docs

all: release

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/%.o: $(SRCDIR)/%.cpp | $(BUILDDIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

release: CXXFLAGS += $(RELEASE_FLAGS)
release: $(BUILDDIR) $(TARGET)

debug: CXXFLAGS += $(DEBUG_FLAGS)
debug: $(BUILDDIR) $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) $(LDFLAGS) -o $@

test: $(BUILDDIR)
	$(CXX) $(CXXFLAGS) $(TEST_SOURCES) -o $(BUILDDIR)/$(TEST_TARGET)
	./$(BUILDDIR)/$(TEST_TARGET)

gtk: CXXFLAGS += $(shell pkg-config --cflags gtk+-3.0)
gtk: LDFLAGS += $(shell pkg-config --libs gtk+-3.0)
gtk: CXXFLAGS += -DUSE_GTK
gtk: release

qt: CXXFLAGS += $(shell qmake -query QT_INSTALL_HEADERS)
qt: LDFLAGS += -lQt5Widgets
qt: CXXFLAGS += -DUSE_QT
qt: release

docs:
	doxygen Doxyfile

clean:
	rm -rf $(BUILDDIR) $(TARGET) $(TEST_TARGET)
	find . -name "*.o" -delete
	find . -name "*.gcno" -delete
	find . -name "*.gcda" -delete
EOF

# README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

A modern C++ application template with GUI support.

## Structure

\`\`\`
$PROJECT_NAME/
├── src/                    # Source files
│   ├── main.cpp            # Entry point
│   └── application.cpp     # Application class
├── include/                # Header files
│   └── application.hpp
├── tests/                  # Unit tests
│   └── test_application.cpp
├── resources/              # Assets (icons, images)
├── docs/                   # Documentation
├── build/                  # Build output
├── CMakeLists.txt          # CMake configuration
├── Makefile                # Make build system
└── README.md               # This file
\`\`\`

## Building

### Using CMake (Recommended)

\`\`\`bash
mkdir build && cd build

# Console version
cmake ..
make

# With GTK
cmake -DUSE_GTK=ON ..
make

# With Qt
cmake -DUSE_QT=ON ..
make

# Build tests
cmake -DBUILD_TESTS=ON ..
make
ctest
\`\`\`

### Using Make

\`\`\`bash
# Release build
make release

# Debug build
make debug

# With GTK
make gtk

# With Qt
make qt

# Run tests
make test

# Clean
make clean
\`\`\`

## Requirements

- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)
- CMake 3.10+ (optional, for CMake build)
- GTK 3.0+ (for GTK build)
- Qt 5.0+ (for Qt build)

### Installing Dependencies

#### Ubuntu/Debian
\`\`\`bash
# For GTK
sudo apt install libgtk-3-dev cmake g++

# For Qt
sudo apt install qtbase5-dev cmake g++
\`\`\`

#### Fedora
\`\`\`bash
# For GTK
sudo dnf install gtk3-devel cmake gcc-c++

# For Qt
sudo dnf install qt5-qtbase-devel cmake gcc-c++
\`\`\`

## Features

- Modern C++17 features
- Cross-platform build system (CMake + Makefile)
- Optional GUI support (GTK or Qt)
- Unit testing framework
- Clean project structure
- Comprehensive documentation setup

## License

MIT License
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Build directories
build/
cmake-build-*/
out/

# Compiled files
*.o
*.obj
*.exe
*.dll
*.so
*.dylib
*.a
*.lib

# Test binaries
test_app
*.gcno
*.gcda

# IDE files
.idea/
.vscode/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Documentation generated files
docs/html/
docs/latex/

# Temporary files
*.tmp
*.bak
EOF

echo ""
echo "✅ Projekt C++ utworzony pomyślnie!"
echo ""
echo "Struktura projektu:"
find "$PROJECT_DIR" -type f | sort | sed "s|$PROJECT_DIR||"
echo ""
echo "Aby zbudować:"
echo "  cd $PROJECT_DIR"
echo "  mkdir build && cd build"
echo "  cmake .."
echo "  make"
echo "  ./my-cpp-app"
echo ""
echo "Lub z GTK:"
echo "  cmake -DUSE_GTK=ON .."
echo "  make"
