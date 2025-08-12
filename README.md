# DpTrim

Connects a [Desktop Pilot Trim Wheel](https://www.desktoppilot.com/product/trim-wheel/) to the hardware trim on a [Brunner](https://brunner-innovation.swiss/) force feedback yoke. This directly affects the forces and neutral position on the yoke's elevator axis, bypassing the simulator.

It's designed for use with [Microsoft Flight Simulator 2024](https://www.flightsimulator.com/microsoft-flight-simulator-2024/), but can work with any simulator that does not directly support force feedback.

## Why?

Most consumer flight simulator yokes operate by returning to a standard neutral position, which cannot be updated by software in realtime.  As such, the only practical way to simulate trim is to have it act like a sort of secondary elevator, that additively adjusts whatever yoke position the user is currently requesting.

This is not how real aircraft trim works, at least in most small aircraft.  In a Cessna 172 (for example), the trim wheel affects the trim tab on the end of the right elevator, and the resulting aerodynamic force will try to push the elevator to a new neutral position.  For example, turning the wheel upwards will push the trim tab upwards, the result of which is to push the rest of the elevator downwards, which (unless countered by the pilot) will then lower the aircraft's nose.

Thus, a real world pilot will typically pitch to the attitude they want — overpowering the aerodynamic forces that want to return the elevator to neutral — then use the trim wheel to remove those forces and set the elevator's new neutral position.

A simulator pilot cannot typically do this, and thus must choose between two less-optimal approaches:

- Pitch to the desired attitude, then adjust the trim wheel **while simultaneously** relaxing their pitch input; or,
- Just directly pitch the plane using the trim wheel.  (This is possible in the real plane as well, but is not how you're supposed to do it.)

However, a simulator pilot **with a force feedback yoke** could absolutely use the real-world trimming method!  The yoke can apply forces to dynamically change its neutral position, matching the real-world behaviour and not requiring any additional elevator forces from the simulator itself.  But since many simulators (such as MSFS2024) do not have native force feedback support, achieving full realism requires an alternate approach.

### Prior MSFS workarounds

In previous versions of Microsoft Flight Simulator, the [recommended setup](https://cls2sim.brunner-innovation.swiss/TrimFunctionality.htm) was to use software trim and **disable simulated aircraft trimming** by editing the `aircraft.cfg` file.

The idea was to adjust the trim knob in the simulator as normal — possibly with the help of a hardware trim device — and have Brunner's CLS2SIM software read and use that trim value.  Since you were using the simulator's trim setting to directly affect the yoke (and thus the elevators), the simulator should not **also** try to trim the aircraft, and should instead leave that to the Brunner yoke.

However, in MSFS 2024, many aircraft are encrypted and cannot easily be edited to disable trimming.  ([I've tried](https://github.com/wisq/msfs2024_no_trim/) but had little success so far.)  Until / unless I can fix this, I'm bypassing MSFS's trim entirely and doing all my trimming in hardware.

## Setup

- Install [Elixir](https://elixir-lang.org/install.html).
- Run `mix deps.get` to fetch dependencies.
- In your Brunner CLS2SIM profile, enable "hardware trim" for your elevator axis.
- In MSFS 2024, disable "AI Auto Trim" under "Settings" → "Assistances".
- Set your simulated aircraft's trim to 0% for maximum accuracy, each flight (and possibly after using autopilot).
  - _(**TODO:** I'm hoping to use [WASimCommander](https://github.com/mpaperno/WASimCommander) to automatically do this in the future.)_

## Operation

Make sure CLS2SIM is running, then run `mix run --no-halt` to autodetect your trim device and immediately begin sending trim data.

Once active, you can begin to make inputs:

- Turning the wheel upwards will increase the forward (nose down) force on the yoke.
- Turning the wheel downwards will increase the backwards (nose up) force on the yoke.
- Turning the sensitivity knob left will reset you to the default (takeoff) trim.
  - This is designed for use in VR, when you can't see the setting in order to reset it.

The default sensitivity is designed to mimic the real Cessna 172, and thus I decided to use the sensitivity knob for other actions.  If you want to change this, edit the values in [device.ex](lib/device.ex).

Note that, depending on your settings, you may not feel any forces until airborne, or at least until there's air running over the elevator, e.g. from prop wash.

## Limitations

The trim setting in the simulator **will not change**, nor will the angle of the rendered trim tab.  This is by design — we are bypassing the simulator and performing trimming on the yoke itself.

## Legal stuff

Copyright © 2025, Adrian Irving-Beer.

DpTrim is released under the [MIT license](LICENSE) and is provided with **no warranty**.  I'm not responsible if your simulated plane crashes, your force feedback yoke punches you in the stomach, your trim wheel catches fire, etc.

DpTrim is not developed by Desktop Pilot, or by Brunner, and is in no way associated with either of them.  All trademarks are the property of their respective owners.
