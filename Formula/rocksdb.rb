class CIRequirement < Requirement
  fatal true
  satisfy { ENV["CIRCLECI"].nil? && ENV["TRAVIS"].nil? }
end

class Rocksdb < Formula
  desc "Embeddable, persistent key-value store for fast storage"
  homepage "http://rocksdb.org"
  url "https://github.com/facebook/rocksdb/archive/v5.7.3.tar.gz"
  sha256 "4868cc95ab9b5dafd7c25f7ffb9fc1c70090fad688e339bfd9180ebb0734ea48"

  bottle do
    cellar :any
    sha256 "235f7b5618adf58735c5499791a010a8ceadff03044bf9a904a96429cbbd77f8" => :sierra
    sha256 "ac5a071d75f8a93a784e7f601c827f68b3006e6705e52f5c5d4ddb93470f519a" => :el_capitan
    sha256 "e0eebc79c484e5581b013236ff10c2578f3f20ba6bd4981609172217f1d29726" => :yosemite
  end

  needs :cxx11
  depends_on "snappy"
  depends_on "lz4"
  depends_on "gflags"
  depends_on "jemalloc"
  unless OS.mac?
    depends_on "bzip2"
    depends_on "zlib"
  end
  depends_on CIRequirement

  def install
    ENV.cxx11
    ENV["PORTABLE"] = "1" if build.bottle?

    # build regular rocksdb
    system "make", "clean"
    system "make", "static_lib"
    system "make", "shared_lib"
    system "make", "tools"
    system "make", "install", "INSTALL_PATH=#{prefix}"

    bin.install "sst_dump" => "rocksdb_sst_dump"
    bin.install "db_sanity_test" => "rocksdb_sanity_test"
    bin.install "db_stress" => "rocksdb_stress"
    bin.install "write_stress" => "rocksdb_write_stress"
    bin.install "ldb" => "rocksdb_ldb"
    bin.install "db_repl_stress" => "rocksdb_repl_stress"
    bin.install "rocksdb_dump"
    bin.install "rocksdb_undump"

    # build rocksdb_lite
    ENV.append_to_cflags "-DROCKSDB_LITE=1"
    ENV["LIBNAME"] = "librocksdb_lite"
    system "make", "clean"
    system "make", "static_lib"
    system "make", "shared_lib"
    system "make", "install", "INSTALL_PATH=#{prefix}"

    if OS.linux?
      # Strip the binaries to reduce their size.
      system "strip", *(Dir[bin/"*"] + Dir[lib/"*"]).select { |f| Pathname.new(f).elf? }
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <assert.h>
      #include <rocksdb/options.h>
      #include <rocksdb/memtablerep.h>
      using namespace rocksdb;
      int main() {
        Options options;
        return 0;
      }
    EOS

    system ENV.cxx, "test.cpp", "-o", "db_test", "-v",
                                "-std=c++11",
                                *(["-stdlib=libc++", "-lstdc++"] if OS.mac?),
                                "-lz", "-lbz2",
                                "-L#{lib}", "-lrocksdb_lite",
                                "-L#{Formula["snappy"].opt_lib}", "-lsnappy",
                                "-L#{Formula["lz4"].opt_lib}", "-llz4"
    system "./db_test"

    assert_match "sst_dump --file=", shell_output("#{bin}/rocksdb_sst_dump --help 2>&1", 1)
    assert_match "rocksdb_sanity_test <path>", shell_output("#{bin}/rocksdb_sanity_test --help 2>&1", 1)
    assert_match "rocksdb_stress [OPTIONS]...", shell_output("#{bin}/rocksdb_stress --help 2>&1", 1)
    assert_match "rocksdb_write_stress [OPTIONS]...", shell_output("#{bin}/rocksdb_write_stress --help 2>&1", 1)
    assert_match "ldb - RocksDB Tool", shell_output("#{bin}/rocksdb_ldb --help 2>&1", 1)
    assert_match "rocksdb_repl_stress:", shell_output("#{bin}/rocksdb_repl_stress --help 2>&1", 1)
    assert_match "rocksdb_dump:", shell_output("#{bin}/rocksdb_dump --help 2>&1", 1)
    assert_match "rocksdb_undump:", shell_output("#{bin}/rocksdb_undump --help 2>&1", 1)
  end
end
