// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../common.dart';
import '../keyboard.dart';
import '../web_driver.dart';

class JsonWireKeyboard extends Keyboard {
  final WebDriver _driver;
  final Resolver _resolver;

  JsonWireKeyboard(this._driver) : _resolver = new Resolver(_driver, '');

  @override
  void sendChord(Iterable<String> chordToSend) {
    sendKeys(_createChord(chordToSend));
  }

  String _createChord(Iterable<String> chord) {
    StringBuffer chordString = new StringBuffer();
    for (String s in chord) {
      chordString.write(s);
    }
    chordString.write(Keyboard.nullChar);

    return chordString.toString();
  }

  @override
  void sendKeys(String keysToSend) {
    _resolver.post('keys', {
      'value': [keysToSend]
    });
  }

  @override
  String toString() => '$_driver.keyboard';

  @override
  int get hashCode => _driver.hashCode;

  @override
  bool operator ==(other) =>
      other is JsonWireKeyboard && other._driver == _driver;
}
