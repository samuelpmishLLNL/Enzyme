; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -gvn -early-cse-memssa -instcombine -instsimplify -simplifycfg -adce -licm -correlated-propagation -instcombine -correlated-propagation -adce -instsimplify -correlated-propagation -jump-threading -instsimplify -early-cse -simplifycfg -S | FileCheck %s

; #include <stdlib.h>
; #include <stdio.h>
;
; struct n {
;     double *values;
;     struct n *next;
; };
;
; __attribute__((noinline))
; double sum_list(const struct n *__restrict node, unsigned long times) {
;     double sum = 0;
;     for(const struct n *val = node; val != 0; val = val->next) {
;         for(int i=0; i<=times; i++) {
;             sum += val->values[i];
;         }
;     }
;     return sum;
; }

%struct.n = type { double*, %struct.n* }
%struct.Gradients = type { double, double, double }

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local double @sum_list(%struct.n* noalias readonly %node, i64 %times) local_unnamed_addr #0 {
entry:
  %cmp18 = icmp eq %struct.n* %node, null
  br i1 %cmp18, label %for.cond.cleanup, label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.cond.cleanup4, %entry
  %val.020 = phi %struct.n* [ %1, %for.cond.cleanup4 ], [ %node, %entry ]
  %sum.019 = phi double [ %add, %for.cond.cleanup4 ], [ 0.000000e+00, %entry ]
  %values = getelementptr inbounds %struct.n, %struct.n* %val.020, i64 0, i32 0
  %0 = load double*, double** %values, align 8, !tbaa !2
  br label %for.body5

for.cond.cleanup:                                 ; preds = %for.cond.cleanup4, %entry
  %sum.0.lcssa = phi double [ 0.000000e+00, %entry ], [ %add, %for.cond.cleanup4 ]
  ret double %sum.0.lcssa

for.cond.cleanup4:                                ; preds = %for.body5
  %next = getelementptr inbounds %struct.n, %struct.n* %val.020, i64 0, i32 1
  %1 = load %struct.n*, %struct.n** %next, align 8, !tbaa !7
  %cmp = icmp eq %struct.n* %1, null
  br i1 %cmp, label %for.cond.cleanup, label %for.cond1.preheader

for.body5:                                        ; preds = %for.body5, %for.cond1.preheader
  %indvars.iv = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next, %for.body5 ]
  %sum.116 = phi double [ %sum.019, %for.cond1.preheader ], [ %add, %for.body5 ]
  %arrayidx = getelementptr inbounds double, double* %0, i64 %indvars.iv
  %2 = load double, double* %arrayidx, align 8, !tbaa !8
  %add = fadd fast double %2, %sum.116
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv, %times
  br i1 %exitcond, label %for.cond.cleanup4, label %for.body5
}

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64) local_unnamed_addr #2

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients @derivative(%struct.n* %x, %struct.n* %xp1, %struct.n* %xp2, %struct.n* %xp3, i64 %n) {
entry:
  %0 = tail call %struct.Gradients (double (%struct.n*, i64)*, ...) @__enzyme_fwddiff(double (%struct.n*, i64)* nonnull @sum_list, metadata !"enzyme_width", i64 3, %struct.n* %x, %struct.n* %xp1, %struct.n* %xp2, %struct.n* %xp3, i64 %n)
  ret %struct.Gradients %0
}

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwddiff(double (%struct.n*, i64)*, ...) #4


attributes #0 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #1 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #2 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #3 = { noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 7.1.0 "}
!2 = !{!3, !4, i64 0}
!3 = !{!"n", !4, i64 0, !4, i64 8}
!4 = !{!"any pointer", !5, i64 0}
!5 = !{!"omnipotent char", !6, i64 0}
!6 = !{!"Simple C/C++ TBAA"}
!7 = !{!3, !4, i64 8}
!8 = !{!9, !9, i64 0}
!9 = !{!"double", !5, i64 0}
!10 = !{!4, !4, i64 0}


; CHECK: define internal [3 x double] @fwddiffe3sum_list(%struct.n* noalias readonly %node, [3 x %struct.n*] %"node'", i64 %times)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %cmp18 = icmp eq %struct.n* %node, null
; CHECK-NEXT:   br i1 %cmp18, label %for.cond.cleanup, label %for.cond1.preheader

; CHECK: for.cond1.preheader:                              ; preds = %entry, %for.cond.cleanup4
; CHECK-NEXT:   %0 = phi [3 x %struct.n*] [ %6, %for.cond.cleanup4 ], [ %"node'", %entry ]
; CHECK-NEXT:   %val.020 = phi %struct.n* [ %7, %for.cond.cleanup4 ], [ %node, %entry ]
; CHECK-NEXT:   %"sum.019'" = phi {{(fast )?}}[3 x double] [ %19, %for.cond.cleanup4 ], [ zeroinitializer, %entry ]
; CHECK-NEXT:   %1 = extractvalue [3 x %struct.n*] %0, 0
; CHECK-NEXT:   %"values'ipg" = getelementptr inbounds %struct.n, %struct.n* %1, i64 0, i32 0
; CHECK-NEXT:   %2 = extractvalue [3 x %struct.n*] %0, 1
; CHECK-NEXT:   %"values'ipg2" = getelementptr inbounds %struct.n, %struct.n* %2, i64 0, i32 0
; CHECK-NEXT:   %3 = extractvalue [3 x %struct.n*] %0, 2
; CHECK-NEXT:   %"values'ipg3" = getelementptr inbounds %struct.n, %struct.n* %3, i64 0, i32 0
; CHECK-NEXT:   %"'ipl" = load double*, double** %"values'ipg", align 8
; CHECK-NEXT:   %"'ipl4" = load double*, double** %"values'ipg2", align 8
; CHECK-NEXT:   %"'ipl5" = load double*, double** %"values'ipg3", align 8
; CHECK-NEXT:   br label %for.body5

; CHECK: for.cond.cleanup:                                 ; preds = %for.cond.cleanup4, %entry
; CHECK-NEXT:   %"sum.0.lcssa'" = phi {{(fast )?}}[3 x double] [ zeroinitializer, %entry ], [ %19, %for.cond.cleanup4 ]
; CHECK-NEXT:   ret [3 x double] %"sum.0.lcssa'"

; CHECK: for.cond.cleanup4:                                ; preds = %for.body5
; CHECK-NEXT:   %"next'ipg" = getelementptr inbounds %struct.n, %struct.n* %1, i64 0, i32 1
; CHECK-NEXT:   %"next'ipg6" = getelementptr inbounds %struct.n, %struct.n* %2, i64 0, i32 1
; CHECK-NEXT:   %"next'ipg7" = getelementptr inbounds %struct.n, %struct.n* %3, i64 0, i32 1
; CHECK-NEXT:   %next = getelementptr inbounds %struct.n, %struct.n* %val.020, i64 0, i32 1
; CHECK-NEXT:   %"'ipl8" = load %struct.n*, %struct.n** %"next'ipg", align 8
; CHECK-NEXT:   %4 = insertvalue [3 x %struct.n*] undef, %struct.n* %"'ipl8", 0
; CHECK-NEXT:   %"'ipl9" = load %struct.n*, %struct.n** %"next'ipg6", align 8
; CHECK-NEXT:   %5 = insertvalue [3 x %struct.n*] %4, %struct.n* %"'ipl9", 1
; CHECK-NEXT:   %"'ipl10" = load %struct.n*, %struct.n** %"next'ipg7", align 8
; CHECK-NEXT:   %6 = insertvalue [3 x %struct.n*] %5, %struct.n* %"'ipl10", 2
; CHECK-NEXT:   %7 = load %struct.n*, %struct.n** %next, align 8, !tbaa !7
; CHECK-NEXT:   %cmp = icmp eq %struct.n* %7, null
; CHECK-NEXT:   br i1 %cmp, label %for.cond.cleanup, label %for.cond1.preheader

; CHECK: for.body5:                                        ; preds = %for.body5, %for.cond1.preheader
; CHECK-NEXT:   %iv1 = phi i64 [ %iv.next2, %for.body5 ], [ 0, %for.cond1.preheader ]
; CHECK-NEXT:   %"sum.116'" = phi {{(fast )?}}[3 x double] [ %19, %for.body5 ], [ %"sum.019'", %for.cond1.preheader ]
; CHECK-NEXT:   %iv.next2 = add nuw nsw i64 %iv1, 1
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds double, double* %"'ipl", i64 %iv1
; CHECK-NEXT:   %"arrayidx'ipg11" = getelementptr inbounds double, double* %"'ipl4", i64 %iv1
; CHECK-NEXT:   %"arrayidx'ipg12" = getelementptr inbounds double, double* %"'ipl5", i64 %iv1
; CHECK-NEXT:   %8 = load double, double* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %9 = load double, double* %"arrayidx'ipg11", align 8
; CHECK-NEXT:   %10 = load double, double* %"arrayidx'ipg12", align 8
; CHECK-NEXT:   %11 = extractvalue [3 x double] %"sum.116'", 0
; CHECK-NEXT:   %12 = fadd fast double %8, %11
; CHECK-NEXT:   %13 = insertvalue [3 x double] undef, double %12, 0
; CHECK-NEXT:   %14 = extractvalue [3 x double] %"sum.116'", 1
; CHECK-NEXT:   %15 = fadd fast double %9, %14
; CHECK-NEXT:   %16 = insertvalue [3 x double] %13, double %15, 1
; CHECK-NEXT:   %17 = extractvalue [3 x double] %"sum.116'", 2
; CHECK-NEXT:   %18 = fadd fast double %10, %17
; CHECK-NEXT:   %19 = insertvalue [3 x double] %16, double %18, 2
; CHECK-NEXT:   %exitcond = icmp eq i64 %iv1, %times
; CHECK-NEXT:   br i1 %exitcond, label %for.cond.cleanup4, label %for.body5
; CHECK-NEXT: }