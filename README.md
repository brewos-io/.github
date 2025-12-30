# BrewOS

<p align="center">
  <img src="firmware/assets/1080/horizontal/full-color/Brewos-1080.png" alt="BrewOS Logo" width="400">
</p>

<p align="center">
  <strong>Open-source firmware for espresso machine control</strong>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#repositories">Repositories</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#community">Community</a>
</p>

---

## Overview

BrewOS is an open-source control system designed to replace factory controllers in espresso machines. It provides enhanced temperature control, real-time monitoring, and modern features while maintaining safety as the top priority.

### Key Features

- 🎯 **Precise PID Control** - Sub-degree temperature stability for consistent shots
- 📱 **WiFi Connected** - Monitor and control via web interface
- 🔧 **Multi-Machine Support** - One firmware for dual boiler, single boiler, and HX machines
- 🛡️ **Safety First** - Hardware watchdogs, interlocks, and fail-safe design
- 📊 **Data Logging** - Track shots, temperatures, and machine statistics
- 🔄 **OTA Updates** - Update firmware wirelessly via web interface
- 🏠 **Home Assistant Integration** - Native integration with MQTT auto-discovery
- ☁️ **Cloud Remote Access** - Control from anywhere via cloud relay

---

## Repositories

This organization contains the following repositories:

### [firmware](https://github.com/brewos-io/firmware) - Main Firmware Repository

The core firmware for BrewOS, including:

- **Pico RP2350 Firmware** - Real-time machine control (PID, boilers, pumps, valves)
- **ESP32-S3 Firmware** - Connectivity hub (WiFi, web server, MQTT, BLE, LVGL display)
- **Web Interface** - Progressive Web App (PWA) for monitoring and control
- **Cloud Service** - Remote access relay service

**Status:** ✅ Active Development  
**Platforms:** RP2350 (Pico), ESP32-S3

### [web](https://github.com/brewos-io/web) - Marketing Website

Marketing and documentation website for the BrewOS project.

- Built with [Astro](https://astro.build/)
- Deployed to GitHub Pages
- Project documentation and marketing content

**Status:** ✅ Active  
**Tech Stack:** Astro, TypeScript

### [homeassistant](https://github.com/brewos-io/homeassistant) - Home Assistant Integration

Home Assistant integration components for BrewOS:

- **Custom Component** - Native HA integration with 35+ entities
- **Lovelace Card** - Custom dashboard card for machine control
- **MQTT Auto-Discovery** - Automatic entity creation
- **Example Automations** - Sample automations and dashboards

**Status:** ✅ Active  
**Integration Methods:** MQTT, Native Component

---

## Quick Start

### Prerequisites

- [Pico SDK](https://github.com/raspberrypi/pico-sdk) (v1.5.0+)
- [ARM GCC Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- [PlatformIO](https://platformio.org/) (for ESP32)
- CMake 3.13+

### Getting Started

1. **Clone the repositories:**

   ```bash
   git clone https://github.com/brewos-io/firmware.git
   git clone https://github.com/brewos-io/web.git
   git clone https://github.com/brewos-io/homeassistant.git
   ```

2. **Set up the firmware:**

   See the [firmware README](https://github.com/brewos-io/firmware#quick-start) for detailed setup instructions.

3. **Explore the documentation:**

   - [Firmware Documentation](https://github.com/brewos-io/firmware/tree/main/docs)
   - [Home Assistant Integration Guide](https://github.com/brewos-io/homeassistant#readme)

---

## Architecture

BrewOS uses a multi-layer architecture:

| Layer           | Components                        | Purpose                           |
| --------------- | --------------------------------- | --------------------------------- |
| **Cloud**       | Google OAuth, Node.js, SQLite     | Remote access via WebSocket relay |
| **ESP32-S3**    | WiFi, Web Server, MQTT, BLE, LVGL | Connectivity & UI hub             |
| **Pico RP2350** | PID, Boiler, Pump, Valve control  | Real-time machine control         |
| **Hardware**    | SSRs, Sensors, Valves             | Physical machine interface        |

For detailed architecture documentation, see the [firmware architecture docs](https://github.com/brewos-io/firmware/tree/main/docs).

---

## Supported Machines

BrewOS supports multiple espresso machine architectures:

| Machine Type       | Status       | Examples                                         |
| ------------------ | ------------ | ------------------------------------------------ |
| **Dual Boiler**    | ✅ Supported | ECM Synchronika, Profitec Pro 700, Lelit Bianca  |
| **Single Boiler**  | ✅ Supported | ECM Barista, Profitec Pro 300, Rancilio Silvia   |
| **Heat Exchanger** | ✅ Supported | ECM Mechanika, Profitec Pro 500, E61 HX machines |
| **Thermoblock**    | 🔮 Planned   | -                                                |

See the [Compatibility List](https://github.com/brewos-io/firmware/blob/main/docs/Compatibility.md) for validated machines.

---

## Documentation

### Getting Started

- [Firmware Setup Guide](https://github.com/brewos-io/firmware/blob/main/SETUP.md)
- [System Architecture](https://github.com/brewos-io/firmware/blob/main/docs/Architecture.md)
- [Quick Start Guide](https://github.com/brewos-io/firmware#quick-start)

### Firmware Documentation

- [Pico Architecture](https://github.com/brewos-io/firmware/blob/main/docs/pico/Architecture.md)
- [ESP32 State Management](https://github.com/brewos-io/firmware/blob/main/docs/esp32/State_Management.md)
- [Communication Protocol](https://github.com/brewos-io/firmware/blob/main/docs/shared/Communication_Protocol.md)

### Integration Guides

- [Home Assistant Integration](https://github.com/brewos-io/homeassistant#readme)
- [MQTT Integration](https://github.com/brewos-io/firmware/blob/main/docs/esp32/integrations/MQTT.md)
- [Cloud Remote Access](https://github.com/brewos-io/firmware/blob/main/docs/cloud/README.md)

### Hardware

- [Hardware Specification](https://github.com/brewos-io/firmware/blob/main/docs/hardware/Specification.md)
- [ESP32 Wiring Guide](https://github.com/brewos-io/firmware/blob/main/docs/hardware/ESP32_Wiring.md)
- [Compatibility List](https://github.com/brewos-io/firmware/blob/main/docs/Compatibility.md)

---

## Contributing

We welcome contributions! Please see the contributing guidelines for each repository:

- [Firmware Contributing Guide](https://github.com/brewos-io/firmware/blob/main/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/brewos-io/firmware/blob/main/CODE_OF_CONDUCT.md)

### Development Priorities

| Priority    | Area         | Description                       |
| ----------- | ------------ | --------------------------------- |
| 🔴 Critical | Safety       | Any safety improvements           |
| 🟠 High     | Stability    | Bug fixes, reliability            |
| 🟡 Medium   | Features     | New machine support, integrations |
| 🟢 Normal   | Enhancements | UI improvements, optimizations    |

---

## Community

- **Discussions:** [GitHub Discussions](https://github.com/brewos-io/firmware/discussions)
- **Issues:** [GitHub Issues](https://github.com/brewos-io/firmware/issues)
- **Testers Needed:** [Become a Tester](https://github.com/brewos-io/firmware/blob/main/TESTERS.md)

---

## Safety Notice

```
⚠️  WARNING: MAINS VOLTAGE

This project involves 100-240V AC mains electricity.
Improper handling can result in death or serious injury.

• Only qualified individuals should work on mains circuits
• Always use isolation transformers during development
• Never work alone on energized equipment
• Disconnect power before making any changes
• Follow all local electrical codes and regulations
```

**Safety is not optional.** The firmware includes multiple safety layers, but hardware installation must be performed by qualified individuals.

---

## License

This project is licensed under the **Apache License 2.0 with Commons Clause**.

**What this means:**

- ✅ You can use, modify, and distribute the software for personal use
- ✅ You can use it for your own espresso machine
- ✅ You can contribute improvements back to the project
- ❌ You cannot sell the software or services based primarily on the software

See individual repository LICENSE files for details.

---

## Acknowledgments

- [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk)
- [ESP-IDF](https://github.com/espressif/esp-idf) & Arduino ESP32
- [PlatformIO](https://platformio.org/)
- The espresso enthusiast community

---

<p align="center">
  <sub>Built with ☕ by espresso enthusiasts, for espresso enthusiasts</sub>
</p>

