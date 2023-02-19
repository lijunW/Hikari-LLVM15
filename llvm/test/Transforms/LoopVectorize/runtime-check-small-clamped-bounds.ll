; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -loop-vectorize -force-vector-width=2 -S %s | FileCheck %s

; Tests where the indices of some accesses are clamped to a small range.

; FIXME: At the moment, the runtime checks require that the indices do not wrap
;        and runtime checks are emitted to ensure that. The clamped indices do
;        wrap, so the vector loops are dead at the moment. But it is still
;        possible to compute the bounds of the accesses and generate proper
;        runtime checks.

; The relevant bounds for %gep.A are [%A, %A+4).
define void @load_clamped_index(i32* %A, i32* %B, i32 %N) {
; CHECK-LABEL: @load_clamped_index(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B1:%.*]] = bitcast i32* [[B:%.*]] to i8*
; CHECK-NEXT:    [[A3:%.*]] = bitcast i32* [[A:%.*]] to i8*
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i32 [[N:%.*]], 2
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[SCALAR_PH:%.*]], label [[VECTOR_SCEVCHECK:%.*]]
; CHECK:       vector.scevcheck:
; CHECK-NEXT:    [[TMP0:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[TMP0]] to i2
; CHECK-NEXT:    [[MUL:%.*]] = call { i2, i1 } @llvm.umul.with.overflow.i2(i2 1, i2 [[TMP1]])
; CHECK-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i2, i1 } [[MUL]], 0
; CHECK-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i2, i1 } [[MUL]], 1
; CHECK-NEXT:    [[TMP2:%.*]] = add i2 0, [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP3:%.*]] = sub i2 0, [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP4:%.*]] = icmp ugt i2 [[TMP3]], 0
; CHECK-NEXT:    [[TMP5:%.*]] = icmp ult i2 [[TMP2]], 0
; CHECK-NEXT:    [[TMP6:%.*]] = select i1 false, i1 [[TMP4]], i1 [[TMP5]]
; CHECK-NEXT:    [[TMP7:%.*]] = icmp ugt i32 [[TMP0]], 3
; CHECK-NEXT:    [[TMP8:%.*]] = or i1 [[TMP6]], [[TMP7]]
; CHECK-NEXT:    [[TMP9:%.*]] = or i1 [[TMP8]], [[MUL_OVERFLOW]]
; CHECK-NEXT:    [[TMP10:%.*]] = or i1 false, [[TMP9]]
; CHECK-NEXT:    br i1 [[TMP10]], label [[SCALAR_PH]], label [[VECTOR_MEMCHECK:%.*]]
; CHECK:       vector.memcheck:
; CHECK-NEXT:    [[TMP11:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    [[TMP12:%.*]] = zext i32 [[TMP11]] to i64
; CHECK-NEXT:    [[TMP13:%.*]] = add nuw nsw i64 [[TMP12]], 1
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i32, i32* [[B]], i64 [[TMP13]]
; CHECK-NEXT:    [[SCEVGEP2:%.*]] = bitcast i32* [[SCEVGEP]] to i8*
; CHECK-NEXT:    [[SCEVGEP4:%.*]] = getelementptr i32, i32* [[A]], i64 [[TMP13]]
; CHECK-NEXT:    [[SCEVGEP45:%.*]] = bitcast i32* [[SCEVGEP4]] to i8*
; CHECK-NEXT:    [[BOUND0:%.*]] = icmp ult i8* [[B1]], [[SCEVGEP45]]
; CHECK-NEXT:    [[BOUND1:%.*]] = icmp ult i8* [[A3]], [[SCEVGEP2]]
; CHECK-NEXT:    [[FOUND_CONFLICT:%.*]] = and i1 [[BOUND0]], [[BOUND1]]
; CHECK-NEXT:    br i1 [[FOUND_CONFLICT]], label [[SCALAR_PH]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i32 [[N]], 2
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i32 [[N]], [[N_MOD_VF]]
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP14:%.*]] = add i32 [[INDEX]], 0
; CHECK-NEXT:    [[TMP15:%.*]] = urem i32 [[TMP14]], 4
; CHECK-NEXT:    [[TMP16:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[TMP15]]
; CHECK-NEXT:    [[TMP17:%.*]] = getelementptr inbounds i32, i32* [[TMP16]], i32 0
; CHECK-NEXT:    [[TMP18:%.*]] = bitcast i32* [[TMP17]] to <2 x i32>*
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <2 x i32>, <2 x i32>* [[TMP18]], align 4, !alias.scope !0
; CHECK-NEXT:    [[TMP19:%.*]] = add <2 x i32> [[WIDE_LOAD]], <i32 10, i32 10>
; CHECK-NEXT:    [[TMP20:%.*]] = getelementptr inbounds i32, i32* [[B]], i32 [[TMP14]]
; CHECK-NEXT:    [[TMP21:%.*]] = getelementptr inbounds i32, i32* [[TMP20]], i32 0
; CHECK-NEXT:    [[TMP22:%.*]] = bitcast i32* [[TMP21]] to <2 x i32>*
; CHECK-NEXT:    store <2 x i32> [[TMP19]], <2 x i32>* [[TMP22]], align 4, !alias.scope !3, !noalias !0
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i32 [[INDEX]], 2
; CHECK-NEXT:    [[TMP23:%.*]] = icmp eq i32 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP23]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP5:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i32 [[N]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i32 [ [[N_VEC]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ], [ 0, [[VECTOR_SCEVCHECK]] ], [ 0, [[VECTOR_MEMCHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[CLAMPED_INDEX:%.*]] = urem i32 [[IV]], 4
; CHECK-NEXT:    [[GEP_A:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[CLAMPED_INDEX]]
; CHECK-NEXT:    [[LV:%.*]] = load i32, i32* [[GEP_A]], align 4
; CHECK-NEXT:    [[ADD:%.*]] = add i32 [[LV]], 10
; CHECK-NEXT:    [[GEP_B:%.*]] = getelementptr inbounds i32, i32* [[B]], i32 [[IV]]
; CHECK-NEXT:    store i32 [[ADD]], i32* [[GEP_B]], align 4
; CHECK-NEXT:    [[IV_NEXT]] = add nuw nsw i32 [[IV]], 1
; CHECK-NEXT:    [[COND:%.*]] = icmp eq i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP7:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %clamped.index = urem i32 %iv, 4
  %gep.A = getelementptr inbounds i32, i32* %A, i32 %clamped.index
  %lv = load i32, i32* %gep.A
  %add = add i32 %lv, 10
  %gep.B = getelementptr inbounds i32, i32* %B, i32 %iv
  store i32 %add, i32* %gep.B
  %iv.next = add nuw nsw i32 %iv, 1
  %cond = icmp eq i32 %iv.next, %N
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}

; The relevant bounds for %gep.A are [%A, %A+4).
define void @store_clamped_index(i32* %A, i32* %B, i32 %N) {
; CHECK-LABEL: @store_clamped_index(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B1:%.*]] = bitcast i32* [[B:%.*]] to i8*
; CHECK-NEXT:    [[A3:%.*]] = bitcast i32* [[A:%.*]] to i8*
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i32 [[N:%.*]], 2
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[SCALAR_PH:%.*]], label [[VECTOR_SCEVCHECK:%.*]]
; CHECK:       vector.scevcheck:
; CHECK-NEXT:    [[TMP0:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[TMP0]] to i2
; CHECK-NEXT:    [[MUL:%.*]] = call { i2, i1 } @llvm.umul.with.overflow.i2(i2 1, i2 [[TMP1]])
; CHECK-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i2, i1 } [[MUL]], 0
; CHECK-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i2, i1 } [[MUL]], 1
; CHECK-NEXT:    [[TMP2:%.*]] = add i2 0, [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP3:%.*]] = sub i2 0, [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP4:%.*]] = icmp ugt i2 [[TMP3]], 0
; CHECK-NEXT:    [[TMP5:%.*]] = icmp ult i2 [[TMP2]], 0
; CHECK-NEXT:    [[TMP6:%.*]] = select i1 false, i1 [[TMP4]], i1 [[TMP5]]
; CHECK-NEXT:    [[TMP7:%.*]] = icmp ugt i32 [[TMP0]], 3
; CHECK-NEXT:    [[TMP8:%.*]] = or i1 [[TMP6]], [[TMP7]]
; CHECK-NEXT:    [[TMP9:%.*]] = or i1 [[TMP8]], [[MUL_OVERFLOW]]
; CHECK-NEXT:    [[TMP10:%.*]] = or i1 false, [[TMP9]]
; CHECK-NEXT:    br i1 [[TMP10]], label [[SCALAR_PH]], label [[VECTOR_MEMCHECK:%.*]]
; CHECK:       vector.memcheck:
; CHECK-NEXT:    [[TMP11:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    [[TMP12:%.*]] = zext i32 [[TMP11]] to i64
; CHECK-NEXT:    [[TMP13:%.*]] = add nuw nsw i64 [[TMP12]], 1
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i32, i32* [[B]], i64 [[TMP13]]
; CHECK-NEXT:    [[SCEVGEP2:%.*]] = bitcast i32* [[SCEVGEP]] to i8*
; CHECK-NEXT:    [[SCEVGEP4:%.*]] = getelementptr i32, i32* [[A]], i64 [[TMP13]]
; CHECK-NEXT:    [[SCEVGEP45:%.*]] = bitcast i32* [[SCEVGEP4]] to i8*
; CHECK-NEXT:    [[BOUND0:%.*]] = icmp ult i8* [[B1]], [[SCEVGEP45]]
; CHECK-NEXT:    [[BOUND1:%.*]] = icmp ult i8* [[A3]], [[SCEVGEP2]]
; CHECK-NEXT:    [[FOUND_CONFLICT:%.*]] = and i1 [[BOUND0]], [[BOUND1]]
; CHECK-NEXT:    br i1 [[FOUND_CONFLICT]], label [[SCALAR_PH]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i32 [[N]], 2
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i32 [[N]], [[N_MOD_VF]]
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP14:%.*]] = add i32 [[INDEX]], 0
; CHECK-NEXT:    [[TMP15:%.*]] = urem i32 [[TMP14]], 4
; CHECK-NEXT:    [[TMP16:%.*]] = getelementptr inbounds i32, i32* [[B]], i32 [[TMP14]]
; CHECK-NEXT:    [[TMP17:%.*]] = getelementptr inbounds i32, i32* [[TMP16]], i32 0
; CHECK-NEXT:    [[TMP18:%.*]] = bitcast i32* [[TMP17]] to <2 x i32>*
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <2 x i32>, <2 x i32>* [[TMP18]], align 4, !alias.scope !8, !noalias !11
; CHECK-NEXT:    [[TMP19:%.*]] = add <2 x i32> [[WIDE_LOAD]], <i32 10, i32 10>
; CHECK-NEXT:    [[TMP20:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[TMP15]]
; CHECK-NEXT:    [[TMP21:%.*]] = getelementptr inbounds i32, i32* [[TMP20]], i32 0
; CHECK-NEXT:    [[TMP22:%.*]] = bitcast i32* [[TMP21]] to <2 x i32>*
; CHECK-NEXT:    store <2 x i32> [[TMP19]], <2 x i32>* [[TMP22]], align 4, !alias.scope !11
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i32 [[INDEX]], 2
; CHECK-NEXT:    [[TMP23:%.*]] = icmp eq i32 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP23]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP13:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i32 [[N]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i32 [ [[N_VEC]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ], [ 0, [[VECTOR_SCEVCHECK]] ], [ 0, [[VECTOR_MEMCHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[CLAMPED_INDEX:%.*]] = urem i32 [[IV]], 4
; CHECK-NEXT:    [[GEP_B:%.*]] = getelementptr inbounds i32, i32* [[B]], i32 [[IV]]
; CHECK-NEXT:    [[LV:%.*]] = load i32, i32* [[GEP_B]], align 4
; CHECK-NEXT:    [[ADD:%.*]] = add i32 [[LV]], 10
; CHECK-NEXT:    [[GEP_A:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[CLAMPED_INDEX]]
; CHECK-NEXT:    store i32 [[ADD]], i32* [[GEP_A]], align 4
; CHECK-NEXT:    [[IV_NEXT]] = add nuw nsw i32 [[IV]], 1
; CHECK-NEXT:    [[COND:%.*]] = icmp eq i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP14:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %clamped.index = urem i32 %iv, 4
  %gep.B = getelementptr inbounds i32, i32* %B, i32 %iv
  %lv = load i32, i32* %gep.B
  %add = add i32 %lv, 10
  %gep.A = getelementptr inbounds i32, i32* %A, i32 %clamped.index
  store i32 %add, i32* %gep.A
  %iv.next = add nuw nsw i32 %iv, 1
  %cond = icmp eq i32 %iv.next, %N
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}

define void @clamped_index_dependence_non_clamped(i32* %A, i32* %B, i32 %N) {
; CHECK-LABEL: @clamped_index_dependence_non_clamped(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[GEP_B:%.*]] = getelementptr inbounds i32, i32* [[B:%.*]], i32 [[IV]]
; CHECK-NEXT:    [[LV:%.*]] = load i32, i32* [[GEP_B]], align 4
; CHECK-NEXT:    [[GEP_A_1:%.*]] = getelementptr inbounds i32, i32* [[A:%.*]], i32 [[IV]]
; CHECK-NEXT:    [[LV_A:%.*]] = load i32, i32* [[GEP_A_1]], align 4
; CHECK-NEXT:    [[ADD:%.*]] = add i32 [[LV]], [[LV_A]]
; CHECK-NEXT:    [[IV_NEXT]] = add nuw nsw i32 [[IV]], 1
; CHECK-NEXT:    [[CLAMPED_INDEX:%.*]] = urem i32 [[IV_NEXT]], 4
; CHECK-NEXT:    [[GEP_A:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[CLAMPED_INDEX]]
; CHECK-NEXT:    store i32 [[ADD]], i32* [[GEP_A]], align 4
; CHECK-NEXT:    [[COND:%.*]] = icmp eq i32 [[IV_NEXT]], [[N:%.*]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT:%.*]], label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %gep.B = getelementptr inbounds i32, i32* %B, i32 %iv
  %lv = load i32, i32* %gep.B
  %gep.A.1 = getelementptr inbounds i32, i32* %A, i32 %iv
  %lv.A = load i32, i32* %gep.A.1
  %add = add i32 %lv, %lv.A

  %iv.next = add nuw nsw i32 %iv, 1
  %clamped.index = urem i32 %iv.next, 4
  %gep.A = getelementptr inbounds i32, i32* %A, i32 %clamped.index
  store i32 %add, i32* %gep.A
  %cond = icmp eq i32 %iv.next, %N
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}

define void @clamped_index_dependence_clamped_index(i32* %A, i32* %B, i32 %N) {
; CHECK-LABEL: @clamped_index_dependence_clamped_index(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[CLAMPED_INDEX_1:%.*]] = urem i32 [[IV]], 4
; CHECK-NEXT:    [[GEP_A_1:%.*]] = getelementptr inbounds i32, i32* [[A:%.*]], i32 [[CLAMPED_INDEX_1]]
; CHECK-NEXT:    [[LV_A:%.*]] = load i32, i32* [[GEP_A_1]], align 4
; CHECK-NEXT:    [[ADD:%.*]] = add i32 [[LV_A]], 10
; CHECK-NEXT:    [[IV_NEXT]] = add nuw nsw i32 [[IV]], 1
; CHECK-NEXT:    [[CLAMPED_INDEX:%.*]] = urem i32 [[IV_NEXT]], 4
; CHECK-NEXT:    [[GEP_A:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[CLAMPED_INDEX]]
; CHECK-NEXT:    store i32 [[ADD]], i32* [[GEP_A]], align 4
; CHECK-NEXT:    [[COND:%.*]] = icmp eq i32 [[IV_NEXT]], [[N:%.*]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT:%.*]], label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %clamped.index.1 = urem i32 %iv, 4
  %gep.A.1 = getelementptr inbounds i32, i32* %A, i32 %clamped.index.1
  %lv.A = load i32, i32* %gep.A.1
  %add = add i32 %lv.A, 10

  %iv.next = add nuw nsw i32 %iv, 1
  %clamped.index = urem i32 %iv.next, 4
  %gep.A = getelementptr inbounds i32, i32* %A, i32 %clamped.index
  store i32 %add, i32* %gep.A
  %cond = icmp eq i32 %iv.next, %N
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}

define void @clamped_index_equal_dependence(i32* %A, i32* %B, i32 %N) {
; CHECK-LABEL: @clamped_index_equal_dependence(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i32 [[N:%.*]], 2
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[SCALAR_PH:%.*]], label [[VECTOR_SCEVCHECK:%.*]]
; CHECK:       vector.scevcheck:
; CHECK-NEXT:    [[TMP0:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[TMP0]] to i2
; CHECK-NEXT:    [[MUL:%.*]] = call { i2, i1 } @llvm.umul.with.overflow.i2(i2 1, i2 [[TMP1]])
; CHECK-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i2, i1 } [[MUL]], 0
; CHECK-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i2, i1 } [[MUL]], 1
; CHECK-NEXT:    [[TMP2:%.*]] = add i2 0, [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP3:%.*]] = sub i2 0, [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP4:%.*]] = icmp ugt i2 [[TMP3]], 0
; CHECK-NEXT:    [[TMP5:%.*]] = icmp ult i2 [[TMP2]], 0
; CHECK-NEXT:    [[TMP6:%.*]] = select i1 false, i1 [[TMP4]], i1 [[TMP5]]
; CHECK-NEXT:    [[TMP7:%.*]] = icmp ugt i32 [[TMP0]], 3
; CHECK-NEXT:    [[TMP8:%.*]] = or i1 [[TMP6]], [[TMP7]]
; CHECK-NEXT:    [[TMP9:%.*]] = or i1 [[TMP8]], [[MUL_OVERFLOW]]
; CHECK-NEXT:    [[TMP10:%.*]] = or i1 false, [[TMP9]]
; CHECK-NEXT:    br i1 [[TMP10]], label [[SCALAR_PH]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i32 [[N]], 2
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i32 [[N]], [[N_MOD_VF]]
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP11:%.*]] = add i32 [[INDEX]], 0
; CHECK-NEXT:    [[TMP12:%.*]] = urem i32 [[TMP11]], 4
; CHECK-NEXT:    [[TMP13:%.*]] = getelementptr inbounds i32, i32* [[A:%.*]], i32 [[TMP12]]
; CHECK-NEXT:    [[TMP14:%.*]] = getelementptr inbounds i32, i32* [[TMP13]], i32 0
; CHECK-NEXT:    [[TMP15:%.*]] = bitcast i32* [[TMP14]] to <2 x i32>*
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <2 x i32>, <2 x i32>* [[TMP15]], align 4
; CHECK-NEXT:    [[TMP16:%.*]] = add <2 x i32> [[WIDE_LOAD]], <i32 10, i32 10>
; CHECK-NEXT:    [[TMP17:%.*]] = bitcast i32* [[TMP14]] to <2 x i32>*
; CHECK-NEXT:    store <2 x i32> [[TMP16]], <2 x i32>* [[TMP17]], align 4
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i32 [[INDEX]], 2
; CHECK-NEXT:    [[TMP18:%.*]] = icmp eq i32 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP18]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP15:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i32 [[N]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i32 [ [[N_VEC]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ], [ 0, [[VECTOR_SCEVCHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[CLAMPED_INDEX:%.*]] = urem i32 [[IV]], 4
; CHECK-NEXT:    [[GEP_A:%.*]] = getelementptr inbounds i32, i32* [[A]], i32 [[CLAMPED_INDEX]]
; CHECK-NEXT:    [[LV_A:%.*]] = load i32, i32* [[GEP_A]], align 4
; CHECK-NEXT:    [[ADD:%.*]] = add i32 [[LV_A]], 10
; CHECK-NEXT:    [[IV_NEXT]] = add nuw nsw i32 [[IV]], 1
; CHECK-NEXT:    store i32 [[ADD]], i32* [[GEP_A]], align 4
; CHECK-NEXT:    [[COND:%.*]] = icmp eq i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP16:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %clamped.index = urem i32 %iv, 4
  %gep.A = getelementptr inbounds i32, i32* %A, i32 %clamped.index
  %lv.A = load i32, i32* %gep.A
  %add = add i32 %lv.A, 10

  %iv.next = add nuw nsw i32 %iv, 1
  store i32 %add, i32* %gep.A
  %cond = icmp eq i32 %iv.next, %N
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}