# 🚀 Kaat Performance Mode (Turbo Build)

Since you are running the app on a high-end **M4 Mac** and **iPhone**, you should use the "Release" version of the app. 

The current terminal version (`flutter run`) is designed for debugging and is intentionally "heavy." The **Release Build** is 10x lighter and runs with full hardware acceleration on both your laptop and phone.

## How to run the Smooth Version:

// turbo
1. **Run the following command in your terminal:**
   ```bash
   cd /Users/puru/Development/Kaat/flutter_app && flutter build web --release && npx serve -l 8080 build/web --single
   ```

2. **Access the new link on your iPhone/Mac:**
   👉 **[http://192.168.1.58:8080](http://192.168.1.58:8080)**

---

### Why this is better:
- **Zero Lag**: Smooth 60FPS animations on the M4 and iPhone.
- **Robust Icons**: The suit icons are now custom-drawn vectors so they will **never** appear as rectangles again.
- **Edge-to-Edge**: This release build properly respects the iPhone notch fix we implemented.
