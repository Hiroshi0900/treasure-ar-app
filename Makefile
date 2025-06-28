# ƹȢ#
test:
	flutter test

test-unit:
	flutter test test/unit

test-widget:
	flutter test test/widget

test-integration:
	flutter test integration_test

test-coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

# Y���թ����
lint:
	flutter analyze
	dart format --set-exit-if-changed .

format:
	dart format .

fix:
	dart fix --apply

# ��ɢ#
build-ios:
	flutter build ios --release

build-debug:
	flutter build ios --debug

# ���ï
check: lint test build-debug

check-full: lint test test-integration build-ios test-coverage

# �X�¡
pub-get:
	flutter pub get

pub-upgrade:
	flutter pub upgrade

pub-outdated:
	flutter pub outdated

# ����Ȣ��
setup: pub-get
	cd ios && pod install

# ������
clean:
	flutter clean
	cd ios && rm -rf Pods && rm Podfile.lock

reset: clean setup

# TDD������
tdd-cycle: test-unit format check