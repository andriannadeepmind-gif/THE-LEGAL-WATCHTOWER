;;;; experiment/runner/toolchain.manifest.sexp
;;;; ΠΑΡΑΓΟΜΕΝΟ από gen-toolchain-manifest.py — μην το γράψεις στο χέρι.

(:lawmax-runner-toolchain/2
 :acquired-at "2026-08-24T11:13:50Z"
 :base-image "ubuntu@sha256:33ceb71981b602c1a7443a53469e4dba065f7503eab3078a2d7a57a2ab987517"
 :sbcl-frozen-version "2.4.0"
 :sbcl-version-decision
  "ΣΥΝΕΙΔΗΤΗ ΕΠΙΛΟΓΗ: το apt της noble δίνει 2.2.9· το repository ΔΗΛΩΝΕΙ
   ARG SBCL_VERSION=2.4.0 (Dockerfile:16) και ΔΕΝ το επιβάλλει (γραμμή 69,
   apt χωρίς έκδοση). Το 2.2.9 ΔΕΝ παρουσιάζεται ως εκπλήρωση του pin.
   Παγώνουμε το ΔΗΛΩΜΕΝΟ 2.4.0, χτισμένο ΑΠΟ ΠΗΓΗ με bootstrap το 2.2.9,
   και η συμβατότητα αποδεικνύεται με ΠΛΗΡΗ census σουιτών πάνω σε αυτό."
 :acquisition-stage
  (:network :required :script "experiment/runner/fetch-toolchain.sh"
   :verification "apt/GPG στα υπογεγραμμένα InRelease+Packages του archive.ubuntu.com
                  ΓΙΑ ΤΑ .deb· ΓΙΑ ΤΟΝ ΠΗΓΑΙΟ SBCL μόνο sha256 των ληφθέντων bytes")
 :construction-stage (:network :disabled :script "experiment/runner/build-runner.sh")
 :residual-assumptions
  ("Ο πηγαίος SBCL ΔΕΝ επαληθεύτηκε με ανεξάρτητη υπογραφή: το .asc του
    sourceforge επιστρέφει HTML σφάλμα και οι keyservers είναι φραγμένοι.
    Άγκυρα = sha256 των ΑΚΡΙΒΩΝ bytes + το URL. ΔΗΛΩΜΕΝΟ ΥΠΟΛΕΙΜΜΑ."
   "Το base image είναι καρφωμένο σε digest· ο mirror.gcr.io δεν μπορεί να το
    νοθεύσει (content-addressed), αλλά η ΕΠΙΛΟΓΗ του digest έγινε σήμερα.")
 :runtime-package-count 41
 :runtime-packages
  ((:package "ca-certificates" :version "20260601~24.04.1" :arch "all"
    :sha256 "6bac2a01979e210d9eac1d4d56747ec709ea60654744d66705dc3c36e7629e50" :bytes 139430 :url "http://archive.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20260601%7e24.04.1_all.deb")
   (:package "git" :version "1:2.43.0-1ubuntu7.3" :arch "amd64"
    :sha256 "099bb129f543adc4c14203334b0fa0a909f8bf038c4d56bc9cc7c774ebf78f87" :bytes 3679758 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/git/git_2.43.0-1ubuntu7.3_amd64.deb")
   (:package "git-man" :version "1:2.43.0-1ubuntu7.3" :arch "all"
    :sha256 "5701f931ed2cd30644700b0fc1cda7c2214f93a63ef84c0c80e43ce40d2cf1d2" :bytes 1100178 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/git/git-man_2.43.0-1ubuntu7.3_all.deb")
   (:package "libbrotli1" :version "1.1.0-2build2" :arch "amd64"
    :sha256 "74492419b8fda803774b8c9acef6afc5d2f9ff31782635aae212906adae7b277" :bytes 330730 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/brotli/libbrotli1_1.1.0-2build2_amd64.deb")
   (:package "libcurl3t64-gnutls" :version "8.5.0-2ubuntu10.12" :arch "amd64"
    :sha256 "85c091cacb80456aeebadd238046f8361847328d81c7625f1a1158133f27310a" :bytes 334674 :url "http://archive.ubuntu.com/ubuntu/pool/main/c/curl/libcurl3t64-gnutls_8.5.0-2ubuntu10.12_amd64.deb")
   (:package "liberror-perl" :version "0.17029-2" :arch "all"
    :sha256 "1907af6bf33dd8684447c09f216c675d2b8559fadd8ddace29fbf83c6fb2a636" :bytes 25632 :url "http://archive.ubuntu.com/ubuntu/pool/main/libe/liberror-perl/liberror-perl_0.17029-2_all.deb")
   (:package "libexpat1" :version "2.6.1-2ubuntu0.4" :arch "amd64"
    :sha256 "126a5612e652bdc2edee19ae8fe4308db72b5b3b0a5581bf885b44a093baf3e5" :bytes 88214 :url "http://archive.ubuntu.com/ubuntu/pool/main/e/expat/libexpat1_2.6.1-2ubuntu0.4_amd64.deb")
   (:package "libgdbm-compat4t64" :version "1.23-5.1build1" :arch "amd64"
    :sha256 "fb8564afd7b7d74d55207070ba50339478e22d29a39ec740dc482f069ac7ee65" :bytes 6710 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gdbm/libgdbm-compat4t64_1.23-5.1build1_amd64.deb")
   (:package "libgdbm6t64" :version "1.23-5.1build1" :arch "amd64"
    :sha256 "18d6d74a5c038b458d95ba0c0909e0f086cd50bb9a0fee32697902724fc5645e" :bytes 34440 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gdbm/libgdbm6t64_1.23-5.1build1_amd64.deb")
   (:package "libgssapi-krb5-2" :version "1.20.1-6ubuntu2.8" :arch "amd64"
    :sha256 "6cd99ec16ae12eb465712f950e43eaf03a8d2a6ab24c00178df56470d5343b66" :bytes 142680 :url "http://archive.ubuntu.com/ubuntu/pool/main/k/krb5/libgssapi-krb5-2_1.20.1-6ubuntu2.8_amd64.deb")
   (:package "libk5crypto3" :version "1.20.1-6ubuntu2.8" :arch "amd64"
    :sha256 "48f689737191cfafaf3c158e9b07d6448f9e6217ad7abbaacc4f96dc95403fa2" :bytes 81946 :url "http://archive.ubuntu.com/ubuntu/pool/main/k/krb5/libk5crypto3_1.20.1-6ubuntu2.8_amd64.deb")
   (:package "libkeyutils1" :version "1.6.3-3build1" :arch "amd64"
    :sha256 "0679f198b0128179e46cdf956fb2022c23c758664c00bc8efa0382d509683a8a" :bytes 9490 :url "http://archive.ubuntu.com/ubuntu/pool/main/k/keyutils/libkeyutils1_1.6.3-3build1_amd64.deb")
   (:package "libkrb5-3" :version "1.20.1-6ubuntu2.8" :arch "amd64"
    :sha256 "63ab8110daea359f55d8135d395de198257acb1f948500c561745addddfece4c" :bytes 347620 :url "http://archive.ubuntu.com/ubuntu/pool/main/k/krb5/libkrb5-3_1.20.1-6ubuntu2.8_amd64.deb")
   (:package "libkrb5support0" :version "1.20.1-6ubuntu2.8" :arch "amd64"
    :sha256 "cee1efc93d4ce4a97db756269824b5a2b90d2cb993cd76102432db60890819fc" :bytes 34688 :url "http://archive.ubuntu.com/ubuntu/pool/main/k/krb5/libkrb5support0_1.20.1-6ubuntu2.8_amd64.deb")
   (:package "libldap2" :version "2.6.10+dfsg-0ubuntu0.24.04.1" :arch "amd64"
    :sha256 "7f3f8e565401256f21d5aa562c9f92dbb63537b73aaea6283e4db5264f1598f4" :bytes 197620 :url "http://archive.ubuntu.com/ubuntu/pool/main/o/openldap/libldap2_2.6.10%2bdfsg-0ubuntu0.24.04.1_amd64.deb")
   (:package "libnghttp2-14" :version "1.59.0-1ubuntu0.4" :arch "amd64"
    :sha256 "73adcbb9df32cd7c9d46b1c7598bbbbcf249be705d62d966694cfc9976a15dfe" :bytes 74590 :url "http://archive.ubuntu.com/ubuntu/pool/main/n/nghttp2/libnghttp2-14_1.59.0-1ubuntu0.4_amd64.deb")
   (:package "libperl5.38t64" :version "5.38.2-3.2ubuntu0.3" :arch "amd64"
    :sha256 "34a46ac768011622bf432873b5c9f53cfe333449602721bc12caadc0e7d1adce" :bytes 4875624 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/perl/libperl5.38t64_5.38.2-3.2ubuntu0.3_amd64.deb")
   (:package "libpsl5t64" :version "0.21.2-1.1build1" :arch "amd64"
    :sha256 "a6c85d1303ae90b6a3209d73c4f047f82c27cdc963c48adfd95dd7abca64f039" :bytes 57072 :url "http://archive.ubuntu.com/ubuntu/pool/main/libp/libpsl/libpsl5t64_0.21.2-1.1build1_amd64.deb")
   (:package "libpython3-stdlib" :version "3.12.3-0ubuntu2.1" :arch "amd64"
    :sha256 "57ebb378c59d2f9ef479bee0abc933c560878cc10e2c3af8e05d6fdb2ed63da4" :bytes 10080 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3-defaults/libpython3-stdlib_3.12.3-0ubuntu2.1_amd64.deb")
   (:package "libpython3.12-minimal" :version "3.12.3-1ubuntu0.15" :arch "amd64"
    :sha256 "5d16abf75f5a517c7e68dfbe888ddb40aa95d3b4445b1c223ec5ea23d2b01051" :bytes 838706 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3.12/libpython3.12-minimal_3.12.3-1ubuntu0.15_amd64.deb")
   (:package "libpython3.12-stdlib" :version "3.12.3-1ubuntu0.15" :arch "amd64"
    :sha256 "47c3b48809d392570e827cb3cdeacdf750af39fc36619c83337e28cbffea791c" :bytes 2070602 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3.12/libpython3.12-stdlib_3.12.3-1ubuntu0.15_amd64.deb")
   (:package "libreadline8t64" :version "8.2-4build1" :arch "amd64"
    :sha256 "563977a16df03b611f5239cc1e9a0426e86479fcc616b5c9e200ea32063119e5" :bytes 152856 :url "http://archive.ubuntu.com/ubuntu/pool/main/r/readline/libreadline8t64_8.2-4build1_amd64.deb")
   (:package "librtmp1" :version "2.4+20151223.gitfa8646d.1-2build7" :arch "amd64"
    :sha256 "967a39dbc14236d1580ede01d80fd78444668572e716734e1ac66c175052594e" :bytes 56342 :url "http://archive.ubuntu.com/ubuntu/pool/main/r/rtmpdump/librtmp1_2.4%2b20151223.gitfa8646d.1-2build7_amd64.deb")
   (:package "libsasl2-2" :version "2.1.28+dfsg1-5ubuntu3.1" :arch "amd64"
    :sha256 "eda097f98dcb3a08b9ce157d6191d140e4885c1cba47b683c94b8ca45e88f458" :bytes 53194 :url "http://archive.ubuntu.com/ubuntu/pool/main/c/cyrus-sasl2/libsasl2-2_2.1.28%2bdfsg1-5ubuntu3.1_amd64.deb")
   (:package "libsasl2-modules-db" :version "2.1.28+dfsg1-5ubuntu3.1" :arch "amd64"
    :sha256 "1f13548b1774cd9c70c50b8c3267204a101334a4d2f979338896ba5a4c6f81b8" :bytes 20354 :url "http://archive.ubuntu.com/ubuntu/pool/main/c/cyrus-sasl2/libsasl2-modules-db_2.1.28%2bdfsg1-5ubuntu3.1_amd64.deb")
   (:package "libsqlite3-0" :version "3.45.1-1ubuntu2.7" :arch "amd64"
    :sha256 "488511119cad001a00f7e00e597112cf743ccfbd3f7a03c82d66237e1bfd82c8" :bytes 701442 :url "http://archive.ubuntu.com/ubuntu/pool/main/s/sqlite3/libsqlite3-0_3.45.1-1ubuntu2.7_amd64.deb")
   (:package "libssh-4" :version "0.10.6-2ubuntu0.4" :arch "amd64"
    :sha256 "c8dcd54390e09aba855ec0565d22396dabe52896c47856cf040b9e1ad37d9ff9" :bytes 190218 :url "http://archive.ubuntu.com/ubuntu/pool/main/libs/libssh/libssh-4_0.10.6-2ubuntu0.4_amd64.deb")
   (:package "libyaml-0-2" :version "0.2.5-1build1" :arch "amd64"
    :sha256 "f5271b120d936dcc7ddf17b9e718df41d55386a6075555d0c634925eaef0b2ac" :bytes 51492 :url "http://archive.ubuntu.com/ubuntu/pool/main/liby/libyaml/libyaml-0-2_0.2.5-1build1_amd64.deb")
   (:package "media-types" :version "10.1.0" :arch "all"
    :sha256 "31bfb7eec55ab6d34a50ba995150e1498d4cb897714085d8025e330d3b529747" :bytes 27474 :url "http://archive.ubuntu.com/ubuntu/pool/main/m/media-types/media-types_10.1.0_all.deb")
   (:package "netbase" :version "6.4" :arch "all"
    :sha256 "8cdbc9c3dca01e660759bf9d840f72e45ac72faf5d19ca1faecacaf6a60c1a87" :bytes 13112 :url "http://archive.ubuntu.com/ubuntu/pool/main/n/netbase/netbase_6.4_all.deb")
   (:package "openssl" :version "3.0.13-0ubuntu3.12" :arch "amd64"
    :sha256 "321b30ad5a1c3783cb3d73ae439f824f6d3874d76a93a62f4a984959b490aa7b" :bytes 1002894 :url "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/openssl_3.0.13-0ubuntu3.12_amd64.deb")
   (:package "perl" :version "5.38.2-3.2ubuntu0.3" :arch "amd64"
    :sha256 "d1c28b1b9b1389a5689d19cc20fb2470d087db2538327371e1c8c7515ef0a041" :bytes 231438 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/perl/perl_5.38.2-3.2ubuntu0.3_amd64.deb")
   (:package "perl-modules-5.38" :version "5.38.2-3.2ubuntu0.3" :arch "all"
    :sha256 "c552fd5fae100049d0a59b681e7896887ec72656dd774deacbdd498189d7432d" :bytes 3110248 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/perl/perl-modules-5.38_5.38.2-3.2ubuntu0.3_all.deb")
   (:package "python3" :version "3.12.3-0ubuntu2.1" :arch "amd64"
    :sha256 "e691b9cc40841c41bbdc50bd794c876cb1b1801306ea27b06e9a1458180df1e9" :bytes 23004 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3-defaults/python3_3.12.3-0ubuntu2.1_amd64.deb")
   (:package "python3-minimal" :version "3.12.3-0ubuntu2.1" :arch "amd64"
    :sha256 "9ba5dd55cdcf6121c147dc5cb87403169b5933e3a56da0de57774f2ce819cf06" :bytes 27442 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3-defaults/python3-minimal_3.12.3-0ubuntu2.1_amd64.deb")
   (:package "python3-yaml" :version "6.0.1-2build2" :arch "amd64"
    :sha256 "315e59500af855f23ee4e95525b99009bd798c4d2658af8eb4b2d66a8a91ec23" :bytes 122568 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/pyyaml/python3-yaml_6.0.1-2build2_amd64.deb")
   (:package "python3.12" :version "3.12.3-1ubuntu0.15" :arch "amd64"
    :sha256 "d02d1769ca198be054f74fab22dc46299b4994c9c00bfdd6352938402e5eed1f" :bytes 650708 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3.12/python3.12_3.12.3-1ubuntu0.15_amd64.deb")
   (:package "python3.12-minimal" :version "3.12.3-1ubuntu0.15" :arch "amd64"
    :sha256 "487383dc2a895e0a767d820e0e55f2ab7d6ebe4dccd3d2c0b81f00ee11bb1152" :bytes 2334180 :url "http://archive.ubuntu.com/ubuntu/pool/main/p/python3.12/python3.12-minimal_3.12.3-1ubuntu0.15_amd64.deb")
   (:package "readline-common" :version "8.2-4build1" :arch "all"
    :sha256 "879bfd7f8a9bc4c0f7cdc777cdd8bc6de5f8c4a2ac80c060322a1b22f13504bb" :bytes 56484 :url "http://archive.ubuntu.com/ubuntu/pool/main/r/readline/readline-common_8.2-4build1_all.deb")
   (:package "sbcl" :version "2:2.2.9-1ubuntu2" :arch "amd64"
    :sha256 "15491132a3e991ab3ce65a5f981ce94e5a7057ee84712ca976e942ab82b47ccc" :bytes 11612036 :url "http://archive.ubuntu.com/ubuntu/pool/universe/s/sbcl/sbcl_2.2.9-1ubuntu2_amd64.deb")
   (:package "tzdata" :version "2026c-0ubuntu0.24.04.1" :arch "all"
    :sha256 "ef12c9ef81905b5ac558504b2f8c20da9be5f28861020b3fb5e8b15fb3fae2f6" :bytes 279816 :url "http://archive.ubuntu.com/ubuntu/pool/main/t/tzdata/tzdata_2026c-0ubuntu0.24.04.1_all.deb")
  )
 :build-package-count 40
 :build-packages
  ((:package "binutils" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "b3b5a84181a38fd191820b2cdcc1a3eeb1cd6333ad472f2092f96e81047e9c74" :bytes 18154 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/binutils_2.42-4ubuntu2.10_amd64.deb")
   (:package "binutils-common" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "d136073f5e2153f3df11c1d08d66727b9466b28ff483f50085f14bbe3464b5ee" :bytes 240286 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/binutils-common_2.42-4ubuntu2.10_amd64.deb")
   (:package "binutils-x86-64-linux-gnu" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "1e510a15f30208d39edcd840e48f26a77bbca7c417805eeccb1e3f7de198ef29" :bytes 2462744 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/binutils-x86-64-linux-gnu_2.42-4ubuntu2.10_amd64.deb")
   (:package "bzip2" :version "1.0.8-5.1build0.1" :arch "amd64"
    :sha256 "71c02f8f7541a2a57f0f3545ee826ad9778e665c5c457f34aca9e71abdc1a22b" :bytes 34534 :url "ΑΓΝΩΣΤΟ")
   (:package "cpp" :version "4:13.2.0-7ubuntu1" :arch "amd64"
    :sha256 "b51f8094760f7b41afdcb1fe1b5a57fc64b75a090859918af17450a10f8c7d31" :bytes 22442 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-defaults/cpp_13.2.0-7ubuntu1_amd64.deb")
   (:package "cpp-13" :version "13.3.0-6ubuntu2~24.04.1" :arch "amd64"
    :sha256 "c7535331fbb183c802c3bf4b6b210872dcc12d0421b3212b3c4b940f2c59ed3a" :bytes 1042 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/cpp-13_13.3.0-6ubuntu2%7e24.04.1_amd64.deb")
   (:package "cpp-13-x86-64-linux-gnu" :version "13.3.0-6ubuntu2~24.04.1" :arch "amd64"
    :sha256 "2ca48bf0c2d6465bc39322899715a85d934b4d7442dd5586a7bebbe3ce0f806b" :bytes 10714542 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/cpp-13-x86-64-linux-gnu_13.3.0-6ubuntu2%7e24.04.1_amd64.deb")
   (:package "cpp-x86-64-linux-gnu" :version "4:13.2.0-7ubuntu1" :arch "amd64"
    :sha256 "85059b30960de3582e8612740614da3dfe47241d0368a28dea686188cf7648dd" :bytes 5326 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-defaults/cpp-x86-64-linux-gnu_13.2.0-7ubuntu1_amd64.deb")
   (:package "gcc" :version "4:13.2.0-7ubuntu1" :arch "amd64"
    :sha256 "0e0bb8b25153ed1c44ab92bc219eed469fcb5820c5c0bc6454b2fd366a33d3ee" :bytes 5018 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-defaults/gcc_13.2.0-7ubuntu1_amd64.deb")
   (:package "gcc-13" :version "13.3.0-6ubuntu2~24.04.1" :arch "amd64"
    :sha256 "7438ff160b020a74970672189ecae25d0ca650de6d7f543f12a3134192cffbd9" :bytes 494262 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/gcc-13_13.3.0-6ubuntu2%7e24.04.1_amd64.deb")
   (:package "gcc-13-base" :version "13.3.0-6ubuntu2~24.04.1" :arch "amd64"
    :sha256 "e859aca26585bb91113a451f1e66bc0e5283cb08797d679aacc1d936ae6dff8e" :bytes 51616 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/gcc-13-base_13.3.0-6ubuntu2%7e24.04.1_amd64.deb")
   (:package "gcc-13-x86-64-linux-gnu" :version "13.3.0-6ubuntu2~24.04.1" :arch "amd64"
    :sha256 "a134b0319a82d14581b3a14820d2832af4ec9778ed8b9b4ddaeecfb0555ec325" :bytes 21084546 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/gcc-13-x86-64-linux-gnu_13.3.0-6ubuntu2%7e24.04.1_amd64.deb")
   (:package "gcc-x86-64-linux-gnu" :version "4:13.2.0-7ubuntu1" :arch "amd64"
    :sha256 "72e79089a10e381360bfc6f03c5e5d8c2ff177d6dbac2cd7ffb3cc1383f57591" :bytes 1212 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-defaults/gcc-x86-64-linux-gnu_13.2.0-7ubuntu1_amd64.deb")
   (:package "libasan8" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "8321aac6230fa1da320e76eb6288b7436164624aec449ed3933ea6c4cc86daac" :bytes 3026656 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libasan8_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libatomic1" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "fe49cbbc7be753528380c724a8eef5f1e31dffa9221f692c5069048d81c7449d" :bytes 10466 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libatomic1_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libbinutils" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "064dce00ce94e1fc2d33779cb0071088f4c8aac79e85345f2e78a020f7d14699" :bytes 576834 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/libbinutils_2.42-4ubuntu2.10_amd64.deb")
   (:package "libc-dev-bin" :version "2.39-0ubuntu8.8" :arch "amd64"
    :sha256 "c894e5a5f137429657d09e853fbbb19d53fc164c60804c396cd43873b0b4f734" :bytes 20418 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc-dev-bin_2.39-0ubuntu8.8_amd64.deb")
   (:package "libc6-dev" :version "2.39-0ubuntu8.8" :arch "amd64"
    :sha256 "bb8741966e7c1d2e2c0b84bb311717a0908fb563d9b2247b7212710e3cd88b94" :bytes 2125374 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.39-0ubuntu8.8_amd64.deb")
   (:package "libcc1-0" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "454456436ca767817a860557263d7cc2489f0a410f03efff4c0bb236d579ec09" :bytes 48002 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libcc1-0_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libcrypt-dev" :version "1:4.4.36-4build1" :arch "amd64"
    :sha256 "2edff420ef80b4a3f3751e65c33423ef30e563122a58b759e4854ea8d84ba1b1" :bytes 111780 :url "http://archive.ubuntu.com/ubuntu/pool/main/libx/libxcrypt/libcrypt-dev_4.4.36-4build1_amd64.deb")
   (:package "libctf-nobfd0" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "da352eb7fa6c4369d2a6c1e5e680f574eda2e38576563326b18d9e47e61c4078" :bytes 98012 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/libctf-nobfd0_2.42-4ubuntu2.10_amd64.deb")
   (:package "libctf0" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "7ec86d697c3668503c85f308a6832f092075b5880ad002f22185264da0bd4645" :bytes 94474 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/libctf0_2.42-4ubuntu2.10_amd64.deb")
   (:package "libgcc-13-dev" :version "13.3.0-6ubuntu2~24.04.1" :arch "amd64"
    :sha256 "cd689db2691edaa10f37329307292796bb599e722e0505c79e14caaa1fe9a93a" :bytes 2680642 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/libgcc-13-dev_13.3.0-6ubuntu2%7e24.04.1_amd64.deb")
   (:package "libgomp1" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "e8a95ec58125b4933597f30ff56c2ae10edf90f287262e366d4b6edea3019144" :bytes 148062 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libgomp1_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libgprofng0" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "1b7e3c2fc162e8358ca6e5a3fffdb4d0d632f790630323215841bb36a63c0ab8" :bytes 848684 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/libgprofng0_2.42-4ubuntu2.10_amd64.deb")
   (:package "libhwasan0" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "2195318cfe68fe16b601913ef7b33c9a900372f57861643fdc9ae6fef84534cd" :bytes 1640706 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libhwasan0_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libisl23" :version "0.26-3build1.1" :arch "amd64"
    :sha256 "4e040926e50fb961fae9bf95660189d468336a4a17bc321872c434fc8f777e7f" :bytes 679812 :url "http://archive.ubuntu.com/ubuntu/pool/main/i/isl/libisl23_0.26-3build1.1_amd64.deb")
   (:package "libitm1" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "1fca498129dd3510294809d77ee754f72a9de281111200e9b7b9a5adf37faa9f" :bytes 29702 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libitm1_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libjansson4" :version "2.14-2build2" :arch "amd64"
    :sha256 "0cf79113f5d193ce9af2be2ff4b2c3b30dd4e55a0b6c47f7d28f6c849ff3aa60" :bytes 32830 :url "http://archive.ubuntu.com/ubuntu/pool/main/j/jansson/libjansson4_2.14-2build2_amd64.deb")
   (:package "liblsan0" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "dc0c2a1a053e833ba4d71e1ec2ba4244fe301761ad4a91d6725f927a52d86a14" :bytes 1321652 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/liblsan0_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libmpc3" :version "1.3.1-1build1.1" :arch "amd64"
    :sha256 "cebe6098bb3d66fdacac9dc6fe406a651216d9c00f27c3f9c159d15d96cdf864" :bytes 54636 :url "http://archive.ubuntu.com/ubuntu/pool/main/m/mpclib3/libmpc3_1.3.1-1build1.1_amd64.deb")
   (:package "libmpfr6" :version "4.2.1-1build1.1" :arch "amd64"
    :sha256 "aebc1c8b69a1f98bb43dfc268daecd181116dbf40b13ee4e822eb4bdd52b493a" :bytes 353020 :url "http://archive.ubuntu.com/ubuntu/pool/main/m/mpfr4/libmpfr6_4.2.1-1build1.1_amd64.deb")
   (:package "libquadmath0" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "dc8f0ca542e09d662f29370c8393c016440dd4bc5c996c5fcc19f632b63ce3b0" :bytes 153316 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libquadmath0_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libsframe1" :version "2.42-4ubuntu2.10" :arch "amd64"
    :sha256 "72093fb456864db55f1352bfa5e952a94f7abaff64e71dff1fbf001db1984564" :bytes 15724 :url "http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/libsframe1_2.42-4ubuntu2.10_amd64.deb")
   (:package "libtsan2" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "8cbcc9b3ae5ef23b449383d47a9035b27596e307d7dce7df9b83d47a7acd1d91" :bytes 2771910 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libtsan2_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "libubsan1" :version "14.2.0-4ubuntu2~24.04.1" :arch "amd64"
    :sha256 "a16dea3abe2dcac99bcfae27e7e5672fde64573c3c170dcb0cd55631238f9814" :bytes 1183812 :url "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libubsan1_14.2.0-4ubuntu2%7e24.04.1_amd64.deb")
   (:package "linux-libc-dev" :version "6.8.0-138.138" :arch "amd64"
    :sha256 "f4186f788e64662d7b10a489b45d7bc953a3b382748ef14f84b2159cd659ff3b" :bytes 1522718 :url "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-libc-dev_6.8.0-138.138_amd64.deb")
   (:package "make" :version "4.3-4.1build2" :arch "amd64"
    :sha256 "1fe6a815b56c7b6e9ce4086a363f09444bbd0a0d30e230c453d0b78e44b57a99" :bytes 179752 :url "http://archive.ubuntu.com/ubuntu/pool/main/m/make-dfsg/make_4.3-4.1build2_amd64.deb")
   (:package "rpcsvc-proto" :version "1.4.2-0ubuntu7" :arch "amd64"
    :sha256 "7eb710fe148d224c159ddec1ceb0ba53ead52a80a6793dcdae1474acf20d8f71" :bytes 67446 :url "http://archive.ubuntu.com/ubuntu/pool/main/r/rpcsvc-proto/rpcsvc-proto_1.4.2-0ubuntu7_amd64.deb")
   (:package "zlib1g-dev" :version "1:1.3.dfsg-3.1ubuntu2.1" :arch "amd64"
    :sha256 "023cbe9dbf0af87f10e54e342c67571874e412b9950d89c6cd7b010be2e67c3c" :bytes 894070 :url "http://archive.ubuntu.com/ubuntu/pool/main/z/zlib/zlib1g-dev_1.3.dfsg-3.1ubuntu2.1_amd64.deb")
  )
 :source-artifacts
  ((:name "sbcl-2.4.0-source.tar.bz2" :sha256 "83d8b74f08d2254c59b9790bc1f669e09099457b884720ececbf45f4b46d1776" :bytes 7695124
    :url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.4.0/sbcl-2.4.0-source.tar.bz2" :signature-verified nil)
  )
 :closure-sha256 "ea3dc6ad04fbed6238f5fe4d258f82f71ad1a545d39189875d1e4e9538f4d330")
