class Gflags < Formula
  desc "Library for processing command-line flags"
  homepage "https://gflags.github.io/gflags/"
  url "https://github.com/gflags/gflags/archive/v2.2.2.tar.gz"
  sha256 "34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf"
  license "BSD-3-Clause"
  revision 1 unless OS.mac?

  bottle do
    cellar :any
    rebuild 1
    sha256 "013d34b7e3e9ef0b1ebae5c0bad9661cf1462a4fddec2e31c27dbacb5e8697b9" => :big_sur
    sha256 "ebc7b6a9b5c14419f01a763f8b5d178525231d0fb4f5a4768673745a893f3b0b" => :catalina
    sha256 "e3176e449321b1e2070a9fabc796e6820f2f0f1f4db1c3916f58e6cdd52e510e" => :mojave
    sha256 "4beffa84f47bdfd9a1a90d9e591d9af4616db464d63046018ef0c58936d58366" => :high_sierra
    sha256 "6f06466ca55f2174daecbc935e0bca1f2aed9bfb94a92f21d52fb4db1e07cd4a" => :sierra
    sha256 "e6c751416ad9906dbb376a079d599b30d19c2d1f36cbaf6a3fa631e4d3123870" => :x86_64_linux
  end

  depends_on "cmake" => :build

  unless OS.mac?
    fails_with gcc: "4"
    fails_with gcc: "5"
    depends_on "gcc@6" => [:build, :test]
  end

  def install
    mkdir "buildroot" do
      system "cmake", "..", *std_cmake_args, "-DBUILD_SHARED_LIBS=ON"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <iostream>
      #include "gflags/gflags.h"

      DEFINE_bool(verbose, false, "Display program name before message");
      DEFINE_string(message, "Hello world!", "Message to print");

      static bool IsNonEmptyMessage(const char *flagname, const std::string &value)
      {
        return value[0] != '\0';
      }
      DEFINE_validator(message, &IsNonEmptyMessage);

      int main(int argc, char *argv[])
      {
        gflags::SetUsageMessage("some usage message");
        gflags::SetVersionString("1.0.0");
        gflags::ParseCommandLineFlags(&argc, &argv, true);
        if (FLAGS_verbose) std::cout << gflags::ProgramInvocationShortName() << ": ";
        std::cout << FLAGS_message;
        gflags::ShutDownCommandLineFlags();
        return 0;
      }
    EOS
    if OS.mac?
      system ENV.cxx, "-L#{lib}", "-lgflags", "test.cpp", "-o", "test"
    else
      system Formula["gcc@6"].bin/"c++-6", "-L#{lib}", "-lgflags", "test.cpp", "-o", "test"
    end
    assert_match "Hello world!", shell_output("./test")
    assert_match "Foo bar!", shell_output("./test --message='Foo bar!'")
  end
end
