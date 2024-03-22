class Beakerlib < Formula
  desc "Shell-level integration testing library"
  homepage "https://github.com/beakerlib/beakerlib"
  url "https://github.com/beakerlib/beakerlib/archive/refs/tags/1.30.tar.gz"
  sha256 "bd06fc61b32d9caf4324587706a8363e37e771355da8297d0c5ba0023ae31098"
  license "GPL-2.0-only"

  on_macos do
    # Fix `readlink`
    depends_on "coreutils"
    depends_on "gnu-getopt"
  end

  patch :DATA

  def install
    system "make", "DD=#{prefix}", "install"
    orig_getopt="declare -r __INTERNAL_GETOPT_CMD=\"getopt\""
    brew_getopt="declare -r __INTERNAL_GETOPT_CMD=\"#{Formula["gnu-getopt"].opt_bin}/getopt\""
    orig_readlink="declare -r __INTERNAL_READLINK_CMD=\"readlink\""
    brew_readlink="declare -r __INTERNAL_READLINK_CMD=\"#{Formula["coreutils"].opt_bin}/greadlink\""
    inreplace "src/beakerlib.sh", orig_getopt, brew_getopt if OS.mac?
    inreplace "src/beakerlib.sh", orig_readlink, brew_readlink if OS.mac?
  end

  test do
    (testpath/"test.sh").write <<~EOS
      #!/usr/bin/env bash
      source #{share}/beakerlib/beakerlib.sh || exit 1
      rlJournalStart
        rlPhaseStartTest
          rlPass "All works"
        rlPhaseEnd
      rlJournalEnd
    EOS
    expected_journal = /\[\s*PASS\s*\]\s*::\s*All works/
    ENV["BEAKERLIB_DIR"] = testpath
    system "bash", "#{testpath}/test.sh"
    assert_match expected_journal, File.read(testpath/"journal.txt")
    assert_match "TESTRESULT_STATE=complete", File.read(testpath/"TestResults")
    assert_match "TESTRESULT_RESULT_STRING=PASS", File.read(testpath/"TestResults")
  end
end

__END__
Subject: [PATCH] Alias `readlink` command
Alias `getopt` command
---
Index: src/beakerlib.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/beakerlib.sh b/src/beakerlib.sh
--- a/src/beakerlib.sh	(revision 35fc9548c22623146d8c9f6935277ee4ea7f24ab)
+++ b/src/beakerlib.sh	(revision fdbbd793beb293ca4bf2640d947d64e8047a5ad4)
@@ -31,6 +31,11 @@
 #   Boston, MA 02110-1301, USA.
 #
 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+# Command aliases for compatibilities. Set them by replacing this string through the Makefile interface
+declare -r __INTERNAL_GETOPT_CMD="getopt"
+declare -r __INTERNAL_READLINK_CMD="readlink"
+
 __INTERNAL_SOURCED=${__INTERNAL_SOURCED-}
 echo "${__INTERNAL_SOURCED}" | grep -qF -- " ${BASH_SOURCE} " && return || __INTERNAL_SOURCED+=" ${BASH_SOURCE} "
 
@@ -475,7 +480,7 @@
 JOBID=${JOBID-}
 RECIPEID=${RECIPEID-}
 BEAKERLIB_JOURNAL=${BEAKERLIB_JOURNAL-}
-export BEAKERLIB=${BEAKERLIB:-$(dirname "$(readlink -e ${BASH_SOURCE})")}
+export BEAKERLIB=${BEAKERLIB:-$(dirname "$($__INTERNAL_READLINK_CMD -e ${BASH_SOURCE})")}
 . $BEAKERLIB/storage.sh
 . $BEAKERLIB/infrastructure.sh
 . $BEAKERLIB/journal.sh
Index: src/infrastructure.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/infrastructure.sh b/src/infrastructure.sh
--- a/src/infrastructure.sh	(revision 35fc9548c22623146d8c9f6935277ee4ea7f24ab)
+++ b/src/infrastructure.sh	(revision fdbbd793beb293ca4bf2640d947d64e8047a5ad4)
@@ -219,7 +219,7 @@
 
 rlMount() {
     local OPTIONS=''
-    local GETOPT=$(getopt -o o: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
+    local GETOPT=$($__INTERNAL_GETOPT_CMD -o o: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
     while true; do
       case $1 in
         --) shift; break; ;;
@@ -288,7 +288,7 @@
 
 rlCheckMount() {
     local MNTOPTS=''
-    local GETOPT=$(getopt -o o: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
+    local GETOPT=$($__INTERNAL_GETOPT_CMD -o o: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
     while true; do
       case $1 in
         --) shift; break; ;;
@@ -383,7 +383,7 @@
 
 rlAssertMount() {
     local MNTOPTS=''
-    local GETOPT=$(getopt -o o: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
+    local GETOPT=$($__INTERNAL_GETOPT_CMD -o o: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
     while true; do
       case $1 in
         --) shift; break; ;;
@@ -461,7 +461,7 @@
 =cut
 
 rlHash() {
-  local GETOPT=$(getopt -o a: -l decode,algorithm:,stdin -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
+  local GETOPT=$($__INTERNAL_GETOPT_CMD -o a: -l decode,algorithm:,stdin -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)); eval set -- "$GETOPT"
   local decode=0 alg="$rlHashAlgorithm" stdin=0
   while true; do
     case $1 in
@@ -637,7 +637,7 @@
     local IFS
 
     # getopt will cut off first long opt when no short are defined
-    OPTS=$(getopt -o "." -l "clean,namespace:,no-missing-ok,missing-ok" -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    OPTS=$($__INTERNAL_GETOPT_CMD -o "." -l "clean,namespace:,no-missing-ok,missing-ok" -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     [ $? -ne 0 ] && return 1
 
     eval set -- "$OPTS"
@@ -713,7 +713,7 @@
         file="$(echo "$file" | sed "s|^\([^/]\)|$PWD/\1|" | sed 's|/$||')"
         # follow symlinks in parent dir
         path="$(dirname "$file")"
-        path="$(readlink -n -m "$path")"
+        path="$($__INTERNAL_READLINK_CMD -n -m "$path")"
         file="$path/$(basename "$file")"
 
         # bail out if the file does not exist
@@ -815,7 +815,7 @@
     local IFS
 
     # getopt will cut off first long opt when no short are defined
-    OPTS=$(getopt -o "n:" -l "namespace:" -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    OPTS=$($__INTERNAL_GETOPT_CMD -o "n:" -l "namespace:" -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     [ $? -ne 0 ] && return 1
 
     eval set -- "$OPTS"
Index: src/logging.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/logging.sh b/src/logging.sh
--- a/src/logging.sh	(revision 35fc9548c22623146d8c9f6935277ee4ea7f24ab)
+++ b/src/logging.sh	(revision fdbbd793beb293ca4bf2640d947d64e8047a5ad4)
@@ -517,7 +517,7 @@
 =cut
 
 rlFileSubmit() {
-    GETOPT=$(getopt -o s: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    GETOPT=$(__INTERNAL_GETOPT_CMD -o s: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     eval set -- "$GETOPT"
 
     SEPARATOR='-'
@@ -551,7 +551,7 @@
             ALIAS=$(echo $ALIAS | tr '/' "$SEPARATOR" | sed "s/^${SEPARATOR}*//")
         fi
         rlLogInfo "Sending $FILE as $ALIAS"
-        ln -s "$(readlink -f $FILE)" "$TMPDIR/$ALIAS"
+        ln -s "$($__INTERNAL_READLINK_CMD -f $FILE)" "$TMPDIR/$ALIAS"
 
         if [ -z "$BEAKERLIB_COMMAND_SUBMIT_LOG" ]
         then
Index: src/storage.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/storage.sh b/src/storage.sh
--- a/src/storage.sh	(revision 35fc9548c22623146d8c9f6935277ee4ea7f24ab)
+++ b/src/storage.sh	(revision 74339d4046351b70b3bf004c1076b4e905c755dc)
@@ -46,7 +46,7 @@
 __INTERNAL_ST_OPTION_PARSER='
   local namespace="$__INTERNAL_STORAGE_DEFAULT_NAMESPACE"
   local section="$__INTERNAL_STORAGE_DEFAULT_SECTION"
-  local GETOPT=$(getopt -o : -l namespace:,section: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)) || return 126
+  local GETOPT=$($__INTERNAL_GETOPT_CMD -o : -l namespace:,section: -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done)) || return 126
   eval set -- "$GETOPT"
   while true; do
     case $1 in
Index: src/synchronisation.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/synchronisation.sh b/src/synchronisation.sh
--- a/src/synchronisation.sh	(revision 35fc9548c22623146d8c9f6935277ee4ea7f24ab)
+++ b/src/synchronisation.sh	(revision 74339d4046351b70b3bf004c1076b4e905c755dc)
@@ -26,9 +26,10 @@
 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 echo "${__INTERNAL_SOURCED}" | grep -qF -- " ${BASH_SOURCE} " && return || __INTERNAL_SOURCED+=" ${BASH_SOURCE} "
 
-getopt -T || ret=$?
+$__INTERNAL_GETOPT_CMD -T || ret=$?
 if [ ${ret:-0} -ne 4 ]; then
     echo "ERROR: Non enhanced getopt version detected" 1>&2
+    echo "getopt command used: $__INTERNAL_GETOPT_CMD" 1>&2
     exit 1
 fi
 
@@ -118,7 +119,7 @@
     shift 1
 
     # that is the GNU extended getopt syntax!
-    local TEMP=$(getopt -o t:p:m:d:r: -n '$routine_name' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    local TEMP=$($__INTERNAL_GETOPT_CMD -o t:p:m:d:r: -n '$routine_name' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     if [[ $? != 0 ]] ; then
         rlLogError "$routine_name: Can't parse command options, terminating..."
         return 127
@@ -348,7 +349,7 @@
     local file=""
 
     # that is the GNU extended getopt syntax!
-    local TEMP=$(getopt -o t:p:d: -n 'rlWaitForFile' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    local TEMP=$($__INTERNAL_GETOPT_CMD -o t:p:d: -n 'rlWaitForFile' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     if [[ $? != 0 ]] ; then
         rlLogError "rlWaitForSocket: Can't parse command options, terminating..."
         return 127
@@ -440,7 +441,7 @@
     local remote=false
 
     # that is the GNU extended getopt syntax!
-    local TEMP=$(getopt -o t:p:d: --longoptions close,remote -n 'rlWaitForSocket' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    local TEMP=$($__INTERNAL_GETOPT_CMD -o t:p:d: --longoptions close,remote -n 'rlWaitForSocket' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     if [[ $? != 0 ]] ; then
         rlLogError "rlWaitForSocket: Can't parse command options, terminating..."
         return 127
@@ -531,7 +532,7 @@
 #'
 rlWait() {
     # that is the GNU extended getopt syntax!
-    local TEMP=$(getopt -o t:s: -n 'rlWait' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    local TEMP=$($__INTERNAL_GETOPT_CMD -o t:s: -n 'rlWait' -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     if [[ $? != 0 ]]; then
         rlLogError "rlWait: Can't parse command options, terminating..."
         return 128
Index: src/testing.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/testing.sh b/src/testing.sh
--- a/src/testing.sh	(revision 35fc9548c22623146d8c9f6935277ee4ea7f24ab)
+++ b/src/testing.sh	(revision 74339d4046351b70b3bf004c1076b4e905c755dc)
@@ -759,7 +759,7 @@
 #'
 
 rlRun() {
-    local __INTERNAL_rlRun_GETOPT=$(getopt -o lcts -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
+    local __INTERNAL_rlRun_GETOPT=$($__INTERNAL_GETOPT_CMD -o lcts -- "$@" 2> >(while read -r line; do rlLogError "$FUNCNAME: $line"; done))
     eval set -- "$__INTERNAL_rlRun_GETOPT"
 
     local __INTERNAL_rlRun_DO_LOG=false
Index: src/libraries.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/libraries.sh b/src/libraries.sh
--- a/src/libraries.sh	(revision 74339d4046351b70b3bf004c1076b4e905c755dc)
+++ b/src/libraries.sh	(revision fdbbd793beb293ca4bf2640d947d64e8047a5ad4)
@@ -114,15 +114,15 @@
 
   if [ ! -e "$0" ]
   then
-    SOURCE="$( readlink -f . )"
+    SOURCE="$( $__INTERNAL_READLINK_CMD -f . )"
   else
-    SOURCE="$( readlink -f $0 )"
+    SOURCE="$( $__INTERNAL_READLINK_CMD -f $0 )"
   fi
 
   local DIR="$( dirname "$SOURCE" )"
   while [ -h "$SOURCE" ]
   do
-      SOURCE="$(readlink -f "$SOURCE")"
+      SOURCE="$($__INTERNAL_READLINK_CMD -f "$SOURCE")"
       [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
       DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
   done
Index: src/rpms.sh
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/src/rpms.sh b/src/rpms.sh
--- a/src/rpms.sh	(revision 74339d4046351b70b3bf004c1076b4e905c755dc)
+++ b/src/rpms.sh	(revision fdbbd793beb293ca4bf2640d947d64e8047a5ad4)
@@ -340,7 +340,7 @@
     {
         status=1
         # expand symlinks (if any)
-        local BINARY=$(readlink -f $FULL_CMD)
+        local BINARY=$($__INTERNAL_READLINK_CMD -f $FULL_CMD)
 
         # get the rpm owning the binary
         local BINARY_RPM=$(rpm -qf --qf="%{name}\n" $BINARY | uniq)
