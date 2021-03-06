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

import 'dart:math' show Point, Rectangle;

import 'by.dart' show byToJson;

import '../../../async_core.dart' as async_core;
import '../common.dart';
import '../web_driver.dart';
import '../web_element.dart';

class JsonWireWebElement implements WebElement, SearchContext {
  final Resolver _resolver;

  @override
  final String id;

  @override
  async_core.WebElement get asyncElement => createAsyncWebElement(this);

  @override
  async_core.SearchContext get asyncContext => asyncElement;

  @override
  final SearchContext context;

  @override
  final WebDriver driver;

  @override
  final dynamic /* String | Finder */ locator;

  @override
  final int index;

  JsonWireWebElement(this.driver, this.id,
      [this.context, this.locator, this.index])
      : _resolver = new Resolver(driver, 'element/$id');

  @override
  void click() {
    _resolver.post('click');
  }

  @override
  void submit() {
    _resolver.post('submit');
  }

  @override
  void sendKeys(String keysToSend) {
    _resolver.post('value', {
      'value': [keysToSend]
    });
  }

  @override
  void clear() {
    _resolver.post('clear');
  }

  @override
  bool get selected => _resolver.get('selected') as bool;

  @override
  bool get enabled => _resolver.get('enabled') as bool;

  @override
  bool get displayed => _resolver.get('displayed') as bool;

  @override
  Point get location {
    final point = _resolver.get('location');
    return new Point<int>(point['x'].toInt(), point['y'].toInt());
  }

  @override
  Rectangle<int> get size {
    final size = _resolver.get('size');
    return new Rectangle<int>(
        0, 0, size['width'].toInt(), size['height'].toInt());
  }

  @override
  Rectangle<int> get rect {
    final location = this.location;
    final size = this.size;
    return new Rectangle<int>(location.x, location.y, size.width, size.height);
  }

  @override
  String get name => _resolver.get('name') as String;

  @override
  String get text => _resolver.get('text') as String;

  @override
  WebElement findElement(By by) {
    final element = _resolver.post('element', byToJson(by));
    return new JsonWireWebElement(
        driver, element[jsonWireElementStr], this, by);
  }

  @override
  List<WebElement> findElements(By by) {
    final elements = _resolver.post('elements', byToJson(by)) as Iterable;
    int i = 0;
    final webElements = <WebElement>[];
    for (final element in elements) {
      webElements.add(new JsonWireWebElement(
          driver, element[jsonWireElementStr], this, by, i++));
    }
    return webElements;
  }

  @override
  Attributes get attributes => new _ElementAttributes(this);

  @override
  Attributes get properties => new _ElementProperties(this);

  @override
  Attributes get cssProperties => new _ElementComputedStyle(this);

  @override
  bool equals(WebElement other) => _resolver.get('equals/${other.id}') as bool;

  @override
  Map<String, String> toJson() => {jsonWireElementStr: id};

  @override
  int get hashCode => driver.hashCode * 3 + id.hashCode;

  @override
  bool operator ==(other) =>
      other is WebElement && other.driver == this.driver && other.id == this.id;

  @override
  String toString() {
    final out = new StringBuffer()..write(context);
    if (locator is By) {
      if (index == null) {
        out..write('.findElement(');
      } else {
        out..write('.findElements(');
      }
      out..write(locator)..write(')');
    } else {
      out..write('.')..write(locator);
    }
    if (index != null) {
      out..write('[')..write(index)..write(']');
    }
    return out.toString();
  }
}

class _ElementAttributes extends Attributes {
  final WebElement element;

  _ElementAttributes(this.element);

  @override
  String operator [](String name) => element.driver.execute('''
    var attr = arguments[0].attributes["$name"];
    if(attr) {
      return attr.value;
    }

    return null;
    ''', [element])?.toString();
}

class _ElementComputedStyle extends Attributes {
  final WebElement element;

  _ElementComputedStyle(this.element);

  @override
  String operator [](String name) => element.driver.execute(
      'return window.getComputedStyle(arguments[0]).${_cssPropName(name)};',
      [element])?.toString();
}

// Retrieves properties via Javascript.
class _ElementProperties extends Attributes {
  final WebElement element;

  _ElementProperties(this.element);

  @override
  String operator [](String name) => element.driver
      .execute('return arguments[0]["$name"];', [element])?.toString();
}

/// Convert hyphenated-properties to camelCase.
String _cssPropName(String name) => name.splitMapJoin(new RegExp(r'-(\w)'),
    onMatch: (m) => m.group(1).toUpperCase(), onNonMatch: (m) => m);
