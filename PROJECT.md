# IBM PC-DOS 1.00 on Real 5150 — Build & Boot Journey

> 1981년 7월 7일 Tim Paterson의 PC-DOS 1.00 dev 소스로부터 출발해
> 부트섹터, IBMBIO, IBMDOS를 직접 빌드하고
> 45년 된 IBM 5150 실기에서 부팅 성공시킨 과정 기록.

---

## 0. 원 저작소 및 이 프로젝트의 의도

원 소스는 GitHub [**DOS-History/Paterson-Listings**](https://github.com/DOS-History/Paterson-Listings)
저장소에 보존되어 있습니다. 이 저장소는 Tim Paterson 이 SCP (Seattle Computer Products)
시절 작성한 86-DOS 와, 그것이 IBM 에 라이선스되어 PC-DOS 1.00 으로 출하되기 직전까지의
개발 단계 소스 listings 을 종이 인쇄본을 스캔/필사한 것입니다. 1980-1981 년에 걸친
여러 시점의 커널 스냅샷이 들어있고, 본 프로젝트가 빌드 대상으로 삼은 것은
**1981-07-07 dev 버전** 입니다.

**이 프로젝트의 의도는 단순합니다 — 저 코드를 실제 IBM 5150 에서 돌려보고 싶었습니다.**

소스 listings 을 읽는 것과, 그 코드가 원래 동작하도록 만들어진 1981 년 하드웨어에서
부팅되는 것을 보는 것은 다른 경험입니다. Paterson listings 에는 커널 (IBMDOS) 은 있지만
주변 glue — 부트섹터, ROM-BIOS 와 통신하는 IBMBIO BIOS layer — 는 listings 에 포함되어
있지 않습니다. 그래서 본 프로젝트는:

1. Paterson 소스를 SCP ASM 2.43 으로 어셈블해 IBMDOS 커널 빌드
2. 부트섹터와 IBMBIO 를 직접 작성 (86-DOS DOSIO.ASM 의 레지스터 수준 컨벤션 참고)
3. 1981 년 IBM PC-DOS 1.00 디스켓과 동일 지오메트리 (160KB SSDD) 의 이미지로 패키징
4. 86Box 에뮬레이터에서 1차 검증 후, **1981 년 8월 첫 출하 5150 에 들어간 04/24/81
   BIOS (U33 ROM `1501476`) 를 가진 실기** 에서 최종 부팅 검증

결과: 1981 년 IBM PC 사용자가 봤을 byte-level boot sequence 가, 공개 archive 된 listings
에서 원시대 하드웨어에서 그대로 재현됨.

---

## 1. 프로젝트 개요

### 목표

IBM PC-DOS 1.00의 1981년 dev 소스를 가져다가:
1. SCP ASM 2.43으로 IBMDOS 커널 빌드
2. 부트섹터 + IBMBIO를 자체 작성 (Paterson 인터페이스 호환)
3. 160KB SSDD 디스켓 이미지로 패키징
4. 86Box 에뮬레이터 검증 통과
5. **실제 IBM 5150 하드웨어에서 부팅**

### 출발점

- 소스: [DOS-History/Paterson-Listings](https://github.com/DOS-History/Paterson-Listings)
- 빌드 도구: SCP ASM 2.43, HEX2BIN
- 에뮬레이터: 86Box (BIOS_5150_24APR81)
- 보유 하드웨어:
  - IBM 5150 (BIOS **04/24/81**, U33 ROM part `1501476` — 오리지널 1981년 8월 출시 BIOS)
  - 5.25" 단면 DD 드라이브 × 2 (한쪽은 헤드 정렬 드리프트, 한쪽은 정상)
  - 펜티엄 PC (DOS 6.0 + 5.25" HD 드라이브)
  - 486 PC
  - Samsung SFD-500P (5.25" DD 드라이브, 추후 확보)
  - 5.25" 2D 디스켓 매체 다수

---

## 2. 빌드 결과물

### 4개 디스켓 이미지 (모두 160KB SSDD, 40 cyl × 1 head × 8 spt × 512 B)

| 이미지 | 설명 | sha256 |
|--------|------|--------|
| `HELLO.IMG` | 진단용 미니멀 부트섹터 (`5150 OK / DRV=0 / READY` 출력) | `fe5c881c...` |
| `PCDOS100.IMG` | 1981 IBM PC-DOS 1.00 정품 (PCjs archive) | `29a4c5eb...` |
| `HYBRID.IMG` | 정품 부트섹터+IBMBIO+COMMAND + 우리 빌드 IBMDOS | `930da2b0...` |
| `SELFBOOT.IMG` | **풀스택 자체빌드** (부트섹터+IBMBIO+IBMDOS 전부 우리 코드) | `02c9b73a...` |

### 자체 작성 소스

- `src/BOOT.ASM` (132 byte) — 자작 부트섹터. INT 13H로 IBMBIO/IBMDOS 로드, 디버그 마커 A/B/C 출력
- `src/IBMBIO.ASM` (~400 byte) — 자작 BIOS 레이어. 10-entry 점프테이블, INT 13/10/16/17/14H 사용
- `src/HELLO.ASM` (146 byte) — 진단용 부트섹터. INT 10H teletype만 사용 (MDA/CGA 모두 호환)

### 빌드 검증

| 단계 | 환경 | 결과 |
|------|------|------|
| Paterson 소스 → IBMDOS.COM (6211 byte) | dosbox-x + SCP ASM | ✓ 첫 5268 byte byte-identical |
| hybrid.img 부팅 | 86Box (PC-DOS 1.00 정품 boot + 우리 IBMDOS) | ✓ Enter today's date |
| selfboot.img 부팅 | 86Box (전체 자체빌드) | ✓ ABCISKXD@@OT@@RC 마커 + Enter today's date |
| selfboot.img 부팅 | **IBM 5150 실기** | ✓ **완전 통과** |

---

## 3. 빌드 과정 핵심 발견

### SCP ASM 2.43 gotchas

- 파일 끝에 **CRLF + 1AH (Ctrl-Z)** 필요. Unix LF는 무한루프
- 문자 리터럴 **반드시 더블쿼트** (`"A"` not `'A'`)
- 라벨에 **언더스코어 금지** (`DPT_A` → 에러, `DPTA`로)
- 숫자 기본 10진. H 접미사로 16진 (`100H`)
- 전방 EQU 참조 불안정 → 라벨 정의 순서 중요

### HEX2BIN 함정

- `ORG 0; PUT 0` 으로 빌드하면 0-byte .COM 출력
- `.COM` 컨벤션이라 `ORG 100H; PUT 100H` 필요

### IBMBIO 점프테이블 구조 (10 entries, not 9)

```
offset 00..02 : DS 3 (unlabeled, INIT entry — 부트섹터가 점프)
offset 03..05 : BIOSSTAT
offset 06..08 : BIOSIN
offset 09..0B : BIOSOUT
offset 0C..0E : BIOSPRINT
offset 0F..11 : BIOSAUXIN
offset 12..14 : BIOSAUXOUT
offset 15..17 : BIOSREAD
offset 18..1A : BIOSWRITE
offset 1B..1D : BIOSDSKCHG
```

처음에 9-entry로 가정해 BIOSSTAT을 offset 0에 두었더니 부트 안 됨. 커널 PRN listing grep으로 `0003 BIOSSTAT: DS 3` 발견 → 10번째 슬롯 추가로 해결.

### 메모리 레이아웃

```
0000:0500..0600  스택 (SS=50, SP=100)
0000:0700        IBMDOS reload area (사용 안 함)
0060:0000        IBMBIO (우리 자작, ~400 byte)
0080:0000        IBMDOS (Paterson 빌드, 6211 byte)
xxxx:0100        COMMAND.COM (DOS가 INT 22h 벡터에 segment 박음)
```

초기에 IBMDOS를 0070에 두었더니 IBMBIO와 겹쳐 충돌. 0080으로 이동해 해결.

### DS 복원 필수

DOSINIT의 CONTINIT가 DS를 자기 CS로 바꾸고 안 되돌림. 우리 IBMBIO가:
```asm
CALL 0,DOSSEG     ; FAR call to IBMDOS init
PUSH CS
POP DS            ; DS 복원 필수
PUSH CS
POP ES
```

### COMMAND.COM 로드 시 DTA 위치

`INT 21h fn 27h` (block read)로 4KB 읽을 때 DTA가 IBMBIO segment 안에 있으면 자기 코드 덮어씀. 해결:
- INT 22h 벡터 (0:008A) 에서 kernel이 박은 COMMAND segment 읽음
- `MOV DS, CMDSEG; SET DTA = 0:0100h` (DS 임시 swap)

---

## 4. 디스켓 굽기 (가장 어려운 부분)

### 도구 비교

| 도구 | 환경 | 장점 | 단점 |
|------|------|------|------|
| **RAWRITE3** (FreeDOS) | DOS | 단순, INT 13h BIOS 기반 | 160KB SSDD 형식 모름 → "can't figure out sectors/track" 에러 |
| **ImageDisk (IMD)** | DOS | 트랙별 verify, 임의 형식 지원 | FDC 직접 프로그래밍 → 환경 까다로움 |
| **WinImage 8.10** | Win 9x/NT | GUI, 안정적 | Windows 필요 |
| **TeleDisk 2.23** | DOS | 옛날 표준 | .TD0 형식만, 우리 .img 못 굽음 |

### RAWRITE3가 안 되는 이유

FreeDOS RAWRITE3는 .img 파일 크기로 형식 추정. 표준 크기 테이블에 160KB (163840 byte) 없음:
- 360KB = 368640 ✓
- 720KB = 737280 ✓
- 1.2MB = 1228800 ✓
- 1.44MB = 1474560 ✓
- 160KB SSDD = 163840 ✗ (테이블에 없음)

→ **ImageDisk + BIN2IMD가 정답**

### BIN2IMD 정확한 명령어

옵션 의미가 직관과 다름:
- `N=` = **실린더 수** (sectors/track 아님)
- `SM=` = sector map (sectors/track + interleave)

160KB SSDD 변환:
```
BIN2IMD HELLO.IMG HELLO.IMD /1 N=40 SM=1-8 SS=512 DM=5
```
- `/1` = 단면
- `N=40` = 40 실린더
- `SM=1-8` = 섹터 1~8 순차 (interleave 1)
- `SS=512` = 512 byte/sector
- `DM=5` = 250kbps MFM Double Density

### IMD Format 메뉴 입력값

| 프롬프트 | 입력값 |
|---------|--------|
| Sectors per track | 8 |
| Start sector | 1 |
| Data rate / type | **250 kbps MFM** |
| Sector size | 512 |
| Cylinders | 40 |
| Sides | 1 |

### IMD Settings (S 메뉴)

DD 드라이브로 DD 굽기:
- Drive: 실제 DD 드라이브 위치 (A 또는 B)
- Cylinders: 40
- Sides: ONE
- Double-Step: **OFF**
- Data rate translation: **NONE / 250kbps native**

HD 드라이브로 DD 굽기 (호환성 문제 있음):
- Double-Step: **ON**
- Data rate translation: **250→300 kbps**

---

## 5. 디스켓 호환성 이슈 (가장 시간 많이 잡아먹은 부분)

### HD vs DD 드라이브 트랙 폭 차이

- HD 드라이브 헤드: 96 TPI (좁음), 0.4mm
- DD 드라이브 헤드: 48 TPI (넓음), 0.5mm

**HD 드라이브로 DD 디스켓 쓰면**:
1. 좁은 트랙으로 자속 박힘
2. DD 드라이브 (5150)가 넓은 헤드로 읽으려 하면 신호가 약함
3. 인접 트랙의 다른 데이터까지 같이 읽혀 노이즈
4. **읽기 자주 실패** → 5150 베이직으로 떨어짐

해결:
- 진짜 40-track DD 드라이브 (Samsung SFD-500P 등) 확보
- DD 드라이브로 굽으면 트랙 폭 5150과 일치 → 호환성 OK

### 5150 드라이브 정렬 드리프트

30년 누적된 헤드 정렬 어긋남으로:
- 자기가 옛날에 쓴 디스켓은 읽음 (자체 정렬 기억)
- 다른 드라이브가 정렬 정확히 쓴 디스켓은 못 읽음

**증상**: DOS 3.3 디스켓은 잘 부팅되는데, 새로 구운 디스켓은 베이직.

해결:
- 헤드 청소 (이소프로필 알코올 + 면봉)
- 5.25" 헤드 클리닝 디스켓
- Greaseweazle (정밀 보정 가능)
- 다른 드라이브로 교체 (5150은 두 드라이브 슬롯 → 하나 망가져도 다른 쪽 사용)

### 본 프로젝트에서 통과한 경로

1. ❌ 펜티엄 HD 드라이브로 RAWRITE3 → 형식 모름 에러
2. ❌ 펜티엄 HD 드라이브로 IMD (Double-Step ON, 250→300) → 5150 베이직
3. ❌ 486 + Samsung SFD-500P DD 드라이브 → 486에서는 부팅 OK, 5150 한쪽 드라이브에서 베이직
4. ✓ **486 + Samsung SFD-500P + 5150의 다른 (정상) 드라이브** → **부팅 성공**

---

## 6. 펜티엄/486에서 굽기 절차

### 사전 준비

```
C:\> CD \5150_KIT\TOOLS\IMD
C:\5150_KIT\TOOLS\IMD> BIN2IMD ..\..\IMG\HELLO.IMG    HELLO.IMD    /1 N=40 SM=1-8 SS=512 DM=5
C:\5150_KIT\TOOLS\IMD> BIN2IMD ..\..\IMG\PCDOS100.IMG PCDOS100.IMD /1 N=40 SM=1-8 SS=512 DM=5
C:\5150_KIT\TOOLS\IMD> BIN2IMD ..\..\IMG\HYBRID.IMG   HYBRID.IMD   /1 N=40 SM=1-8 SS=512 DM=5
C:\5150_KIT\TOOLS\IMD> BIN2IMD ..\..\IMG\SELFBOOT.IMG SELFBOOT.IMD /1 N=40 SM=1-8 SS=512 DM=5
```

### IMD로 굽기

```
C:\5150_KIT\TOOLS\IMD> IMD
```

1. `S` (Settings) → Drive=B (또는 A), Cylinders=40, Sides=ONE, Double-Step=OFF
2. ESC → 메인 메뉴
3. `W` (Write) → Filename=HELLO.IMD, Drive=B, "Verify after write?" Y
4. 40트랙 진행 + verify
5. ESC → 메뉴
6. 디스켓 빼고 새 디스켓 넣고 W 다시 → 다음 .IMD

### DEBUG로 굽기 검증

```
C:\> DEBUG
-L 100 1 0 1            ← 드라이브 1(B:), 섹터 0, 1개를 메모리 100h
-D 100 L 20             ← 32 byte 덤프
-Q
```

기대 패턴:
- HELLO: `8A E2 FA 33 C0 8E D8 8E ...`
- HYBRID/PCDOS100: `EB 2F 14 00 00 00 60 00 20 37 2D 00 ...`
- SELFBOOT: `FA 33 C0 8E D8 8E C0 8E ...`

`00 00 00...` 만 보이면 굽기 실패 (다시).
첫 byte 비트 손상 (예: EB → 2B)이면 자속 약함 → 매체 또는 드라이브 문제.

---

## 7. 5150 BIOS 버전 확인

### 방법 A: BASIC PEEK

DOS 또는 카세트 BASIC에서:
```basic
DEFSEG=&HF000:FORI=&HFFF5TO&HFFFC:?CHR$(PEEK(I));:NEXT
```

출력:
- `04/24/81` → 오리지널 5150
- `10/19/81` → 개정 A (320KB DSDD 추가)
- `10/27/82` → 개정 B (360KB 9-spt 추가)

### 방법 B: ROM 칩 라벨

메인보드 U33 소켓 ROM 칩:
- `1501476` / `5700051` → 04/24/81
- `5700671` → 10/19/81
- 후기 → 10/27/82

### BIOS별 지원 형식

| BIOS | 160KB SSDD | 180KB SSDD | 320KB DSDD | 360KB DSDD |
|------|:--:|:--:|:--:|:--:|
| 04/24/81 | ✓ | ✗ | ✗ | ✗ |
| 10/19/81 | ✓ | ✓ | ✓ | ✗ |
| 10/27/82 | ✓ | ✓ | ✓ | ✓ |

---

## 8. SELFBOOT.IMG 부팅 시 화면 마커 해석

```
ABCISKXD@@OT@@RC@@@@@@@@@@
Enter today's date (m-d-y): _
```

| 마커 | 의미 |
|------|------|
| A | 자작 부트섹터 진입 (CLI/STI 후) |
| B | IBMBIO 4섹터 read 성공 |
| C | IBMDOS 13섹터 read 성공, 0060:0000으로 far jump |
| I | IBMBIO INIT 진입 |
| S | 스택 + DS 설정 완료 |
| K | DOSINIT far call 직전 |
| X | DOSINIT 정상 복귀, DS 복원 완료 |
| D | INT 21h fn 0Fh (Open) 호출 직전 |
| @ | DREAD (BIOSREAD) 호출 시 (디스크 read) — COMMAND.COM 로드 중 여러 번 |
| O | Open 성공 |
| T | DTA 설정 완료 (CMDSEG:0100h) |
| R | INT 21h fn 27h (block read) 완료 |
| C | COMMAND.COM far jump 직전 (마지막 마커) |

이후 COMMAND.COM이 `Enter today's date` 출력.

### 부팅 실패 위치 진단

- `ABC` 만 → 부트섹터에서 IBMBIO INIT 호출 안 됨
- `ABCI` → IBMBIO 진입했지만 stack/segment 설정 단계 실패
- `ABCISK` → DOSINIT 호출 후 안 돌아옴 (메모리 충돌 의심)
- `ABCISKXD` 후 `!` → BADCMD (Open 실패)
- `ABCISKXD@@OT@@RC` 후 멈춤 → COMMAND.COM 로드는 됐지만 jump 실패

---

## 9. 디렉터리 구조 (공개 저장소)

```
.
├── README.md               ← GitHub entry point
├── PROJECT.md              ← 본 문서
├── BUILD.md                ← 빌드 가이드 (외부 의존성 안내)
├── LICENSE                 ← MIT (우리 작성물 한정)
├── .gitignore
├── src/                    ← 우리가 작성한 소스
│   ├── BOOT.ASM            (132 byte 부트섹터)
│   ├── IBMBIO.ASM          (~400 byte BIOS layer)
│   └── HELLO.ASM           (146 byte 진단 부트섹터)
├── scripts/
│   ├── build.sh            ← Paterson → hybrid.img 빌드
│   ├── build_full.sh       ← 풀스택 selfboot.img 빌드
│   └── pcjs2img.py         ← PCjs JSON → 평면 .img 변환
├── images/
│   └── HELLO.IMG           ← 우리 코드만 들어있는 진단용 (배포 가능)
└── docs/                   ← 한글 절차 문서
    ├── burning-procedure-ko.txt
    └── hardware-test-procedure-ko.txt
```

저작권상 공개 저장소에 포함하지 않은 것 (사용자가 직접 확보):

- `Paterson-Listings/` — DOS-History/Paterson-Listings 별도 clone
- `build/refs/PCDOS100.img` — IBM 1981 (PCjs archive에서)
- `build/tools/ASM.COM`, `HEX2BIN.COM` — SCP
- `build/86box-vm/` — IBM 5150 ROM 포함
- `build/burners/` — RawWrite/IMD/WinImage 등 third-party
- `build/images/HYBRID.IMG`, `SELFBOOT.IMG` — IBM COMMAND.COM 포함

자세한 위치 및 입수 방법은 [BUILD.md](BUILD.md) 참고.

dist/
└── 5150_KIT.zip           ← 펜티엄/486 이동용 패키지 (gitignored)
```

---

## 10. 결과 요약

✓ Tim Paterson의 1981-07-07 PC-DOS 1.00 dev 소스로부터 IBMDOS.COM 6211 byte 빌드
✓ 부트섹터 (132 byte) + IBMBIO (~400 byte) 직접 작성
✓ 86Box 에뮬레이터에서 풀스택 부팅 검증
✓ ImageDisk + Samsung SFD-500P DD 드라이브로 5150용 디스켓 굽기 성공
✓ **45년 된 IBM 5150 실기 (BIOS 04/24/81, 가장 오리지널 1981년 8월 ROM) 에서 SELFBOOT.IMG 완전 부팅** — 모든 마커 통과 + COMMAND.COM 진입 + Enter today's date prompt

### 1981년 PC-DOS 1.00 의 모든 코드 layer를 우리 손으로 재구성:

| Layer | 출처 | 우리 작업 |
|-------|------|-----------|
| 부트섹터 | Tim Paterson 인터페이스 | **자작 (BOOT.ASM)** |
| IBMBIO | 86-DOS DOSIO.ASM 참고 | **자작 (IBMBIO.ASM)** |
| IBMDOS (kernel) | Paterson 1981-07-07 dev | **소스에서 빌드 (6211 byte)** |
| COMMAND.COM | IBM 1981 정품 | 그대로 사용 |

---

## 11. 참고 자료

- [Paterson-Listings GitHub](https://github.com/DOS-History/Paterson-Listings) — 1981년 dev 소스
- [PCjs](https://www.pcjs.org/software/pcx86/sys/dos/ibm/1.00/) — 1981 PC-DOS 1.00 디스크 archive
- [86Box](https://86box.net/) — IBM 5150 에뮬레이터
- [ImageDisk by Dave Dunfield](http://dunfield.classiccmp.org/img/) — DD/HD/SD 디스켓 굽기
- [chrysocome RawWrite](http://www.chrysocome.net/rawwrite) — Win32 raw image writer

---

*최종 업데이트: 2026-05-01 (5150 실기 부팅 성공일)*
