# 제한 사항

아시다시피 Isar 는 VM 에서 실행되는 모바일 장치 및 데스크톱과 웹에서 작동합니다. 두 플랫폼은 매우 다르고 다른 한계점을 가지고 있습니다.
As you know, Isar works on mobile devices and desktops running on the VM as well as Web. Both platforms are very different and have different limitations.

## VM 에서의 제한사항

- where 절에는 문자열의 처음 1024바이트만 사용할 수 있습니다.
- 객체의 크기는 16MB 를 넘을 수 없습니다.

## 웹 에서의 제한사항

Isar Web 은 IndexedDB 에 의존하고 있습니다. 그래서 더 많은 제약이 있지만, Isar 를 사용하는 동안 거의 눈치채기 어렵습니다.

- 동기식 메서드들은 지원되지 않습니다.
- 현재 `Isar.splitWords()` 및 `.matches()` 필터가 구현되지 않았습니다.
- 스키마 변경 사항이 VM에서만큼 엄격하게 확인되지 않기 때문에 규칙을 준수하도록 주의하십시오.
- 모든 숫자 유형이 두 배(js의 number 타입) 으로 저장되므로 `@Size32` 가 효과가 없습니다.
- 해시 인덱스가 더 적은 공간을 사용하지 않도록 인덱스가 다르게 표기됩니다.(여전히 동일하게 작동합니다.)
- `col.delete()` 및 `col.deleteAll()` 이 올바르게 작동하지만 반환 값은 올바르지 않습니다.
- `col.clear()` 자동 증분 값을 초기화 하지 않습니다.
- `NaN` 값으로 지원되지 않습니다.
