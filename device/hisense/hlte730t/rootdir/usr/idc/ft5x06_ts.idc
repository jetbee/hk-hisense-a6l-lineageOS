# SPDX-License-Identifier: Apache-2.0
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Emulator keyboard configuration file #1.
#
device.internal = 0

# hlte730t: as an external device this panel would wake the phone on any
# touch while the screen is off (InputReader defaults touch.wake to
# isExternal), so holding the phone by the E-ink side wakes it.
touch.wake = 0
