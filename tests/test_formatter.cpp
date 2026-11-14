#include "../core/src/format/formatter.h"

#include <cassert>
#include <cstdio>
#include <cstring>
#include <string>

using namespace kikoe;

namespace {

SegmentList sample_segments()
{
    SegmentList s;
    Segment a; a.start_ms = 0;    a.end_ms = 2500;  a.text = " Halo dunia. ";
    Segment b; b.start_ms = 2500; b.end_ms = 5340;  b.text = "Ini uji coba.";
    s.push_back(a);
    s.push_back(b);
    return s;
}

void test_parse_format()
{
    OutputFormat fmt;
    assert(parse_format("TXT", fmt) && fmt == OutputFormat::Txt);
    assert(parse_format("Srt", fmt) && fmt == OutputFormat::Srt);
    assert(parse_format("vtt", fmt) && fmt == OutputFormat::Vtt);
    assert(parse_format("json", fmt) && fmt == OutputFormat::Json);
    assert(!parse_format("docx", fmt));
    assert(!parse_format("", fmt));
}

void test_txt_trims_and_newlines()
{
    const std::string out = format_segments(sample_segments(), OutputFormat::Txt);
    assert(out == "Halo dunia.\nIni uji coba.\n");
}

void test_srt_structure()
{
    const std::string out = format_segments(sample_segments(), OutputFormat::Srt);
    const char* expected =
        "1\n00:00:00,000 --> 00:00:02,500\nHalo dunia.\n\n"
        "2\n00:00:02,500 --> 00:00:05,340\nIni uji coba.\n\n";
    assert(out == expected);
}

void test_vtt_structure()
{
    const std::string out = format_segments(sample_segments(), OutputFormat::Vtt);
    const char* expected =
        "WEBVTT\n\n"
        "00:00:00.000 --> 00:00:02.500\nHalo dunia.\n\n"
        "00:00:02.500 --> 00:00:05.340\nIni uji coba.\n\n";
    assert(out == expected);
}

void test_json_escapes()
{
    SegmentList s;
    Segment a; a.start_ms = 1; a.end_ms = 2; a.text = "line1\nline2 quote \" and \\";
    s.push_back(a);
    const std::string out = format_segments(s, OutputFormat::Json);
    assert(out.find("\\\"") != std::string::npos);
    assert(out.find("\\\\") != std::string::npos);
    assert(out.find("\\n") != std::string::npos);
    assert(out.front() == '{');
    assert(out.back() == '\n');
}

void test_hours_timestamp()
{
    SegmentList s;
    Segment a; a.start_ms = 3723456; a.end_ms = 3723456 + 1000; a.text = "x";
    s.push_back(a);
    const std::string out = format_segments(s, OutputFormat::Srt);
    assert(out.find("01:02:03,456 --> 01:02:04,456") != std::string::npos);
}

} // namespace

int main()
{
    test_parse_format();
    test_txt_trims_and_newlines();
    test_srt_structure();
    test_vtt_structure();
    test_json_escapes();
    test_hours_timestamp();
    std::printf("kikoe formatter ok\n");
    return 0;
}
