; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=aarch64-apple-darwin -fast-isel -fast-isel-abort=1 -verify-machineinstrs < %s | FileCheck %s

%struct.foo = type { i32, i64, float, double }

define double* @test_struct(%struct.foo* %f) {
; CHECK-LABEL: test_struct:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add x0, x0, #24
; CHECK-NEXT:    ret
  %1 = getelementptr inbounds %struct.foo, %struct.foo* %f, i64 0, i32 3
  ret double* %1
}

define i32* @test_array1(i32* %a, i64 %i) {
; CHECK-LABEL: test_array1:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov x8, #4
; CHECK-NEXT:    madd x0, x1, x8, x0
; CHECK-NEXT:    ret
  %1 = getelementptr inbounds i32, i32* %a, i64 %i
  ret i32* %1
}

define i32* @test_array2(i32* %a) {
; CHECK-LABEL: test_array2:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add x0, x0, #16
; CHECK-NEXT:    ret
  %1 = getelementptr inbounds i32, i32* %a, i64 4
  ret i32* %1
}

define i32* @test_array3(i32* %a) {
; CHECK-LABEL: test_array3:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add x0, x0, #1, lsl #12 ; =4096
; CHECK-NEXT:    ret
  %1 = getelementptr inbounds i32, i32* %a, i64 1024
  ret i32* %1
}

define i32* @test_array4(i32* %a) {
; CHECK-LABEL: test_array4:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov x8, #4104
; CHECK-NEXT:    add x0, x0, x8
; CHECK-NEXT:    ret
  %1 = getelementptr inbounds i32, i32* %a, i64 1026
  ret i32* %1
}

define i32* @test_array5(i32* %a, i32 %i) {
; CHECK-LABEL: test_array5:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    ; kill: def $w1 killed $w1 def $x1
; CHECK-NEXT:    mov x8, #4
; CHECK-NEXT:    sxtw x9, w1
; CHECK-NEXT:    madd x0, x9, x8, x0
; CHECK-NEXT:    ret
  %1 = getelementptr inbounds i32, i32* %a, i32 %i
  ret i32* %1
}