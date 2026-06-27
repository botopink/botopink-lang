/* ANSI-C code produced by gperf version 3.3 */
/* Command-line: gperf -t /tmp/atomvm-inspect/src/libAtomVM/nifs.gperf  */
/* Computed positions: -k'6,8,10,14,18,$' */

#if !((' ' == 32) && ('!' == 33) && ('"' == 34) && ('#' == 35) \
      && ('%' == 37) && ('&' == 38) && ('\'' == 39) && ('(' == 40) \
      && (')' == 41) && ('*' == 42) && ('+' == 43) && (',' == 44) \
      && ('-' == 45) && ('.' == 46) && ('/' == 47) && ('0' == 48) \
      && ('1' == 49) && ('2' == 50) && ('3' == 51) && ('4' == 52) \
      && ('5' == 53) && ('6' == 54) && ('7' == 55) && ('8' == 56) \
      && ('9' == 57) && (':' == 58) && (';' == 59) && ('<' == 60) \
      && ('=' == 61) && ('>' == 62) && ('?' == 63) && ('A' == 65) \
      && ('B' == 66) && ('C' == 67) && ('D' == 68) && ('E' == 69) \
      && ('F' == 70) && ('G' == 71) && ('H' == 72) && ('I' == 73) \
      && ('J' == 74) && ('K' == 75) && ('L' == 76) && ('M' == 77) \
      && ('N' == 78) && ('O' == 79) && ('P' == 80) && ('Q' == 81) \
      && ('R' == 82) && ('S' == 83) && ('T' == 84) && ('U' == 85) \
      && ('V' == 86) && ('W' == 87) && ('X' == 88) && ('Y' == 89) \
      && ('Z' == 90) && ('[' == 91) && ('\\' == 92) && (']' == 93) \
      && ('^' == 94) && ('_' == 95) && ('a' == 97) && ('b' == 98) \
      && ('c' == 99) && ('d' == 100) && ('e' == 101) && ('f' == 102) \
      && ('g' == 103) && ('h' == 104) && ('i' == 105) && ('j' == 106) \
      && ('k' == 107) && ('l' == 108) && ('m' == 109) && ('n' == 110) \
      && ('o' == 111) && ('p' == 112) && ('q' == 113) && ('r' == 114) \
      && ('s' == 115) && ('t' == 116) && ('u' == 117) && ('v' == 118) \
      && ('w' == 119) && ('x' == 120) && ('y' == 121) && ('z' == 122) \
      && ('{' == 123) && ('|' == 124) && ('}' == 125) && ('~' == 126))
/* The character set is not based on ISO-646.  */
#error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gperf@gnu.org>."
#endif

#line 24 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"

#include <string.h>
typedef struct NifNameAndNifPtr NifNameAndNifPtr;
#line 28 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
struct NifNameAndNifPtr
{
  const char *name;
  const struct Nif *nif;
};

#define TOTAL_KEYWORDS 154
#define MIN_WORD_LENGTH 10
#define MAX_WORD_LENGTH 40
#define MIN_HASH_VALUE 35
#define MAX_HASH_VALUE 518
/* maximum key range = 484, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned short asso_values[] =
    {
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519,   0, 519, 519, 519, 519, 519, 519,
      519, 519, 519,   5, 519, 519, 519, 135,  35,   5,
        0,  70,   5, 519, 519, 519, 519, 519,  35, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519,  15, 519,  90,  10, 130,
       70,   5,  35,  65,  55,  10, 519,   0,  10, 100,
       20,   0,  10, 519,   5,   5,   0,  50, 519, 150,
       50, 160, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519, 519, 519, 519, 519,
      519, 519, 519, 519, 519, 519
    };
  register unsigned int hval = len;

  switch (hval)
    {
      default:
        hval += asso_values[(unsigned char)str[17]];
#if (defined __cplusplus && (__cplusplus >= 201703L || (__cplusplus >= 201103L && defined __clang__ && __clang_major__ + (__clang_minor__ >= 9) > 3))) || (defined __STDC_VERSION__ && __STDC_VERSION__ >= 202000L && ((defined __GNUC__ && __GNUC__ >= 10) || (defined __clang__ && __clang_major__ >= 9)))
      [[fallthrough]];
#elif (defined __GNUC__ && __GNUC__ >= 7) || (defined __clang__ && __clang_major__ >= 10)
      __attribute__ ((__fallthrough__));
#endif
      /*FALLTHROUGH*/
      case 17:
      case 16:
      case 15:
      case 14:
        hval += asso_values[(unsigned char)str[13]];
#if (defined __cplusplus && (__cplusplus >= 201703L || (__cplusplus >= 201103L && defined __clang__ && __clang_major__ + (__clang_minor__ >= 9) > 3))) || (defined __STDC_VERSION__ && __STDC_VERSION__ >= 202000L && ((defined __GNUC__ && __GNUC__ >= 10) || (defined __clang__ && __clang_major__ >= 9)))
      [[fallthrough]];
#elif (defined __GNUC__ && __GNUC__ >= 7) || (defined __clang__ && __clang_major__ >= 10)
      __attribute__ ((__fallthrough__));
#endif
      /*FALLTHROUGH*/
      case 13:
      case 12:
      case 11:
      case 10:
        hval += asso_values[(unsigned char)str[9]];
#if (defined __cplusplus && (__cplusplus >= 201703L || (__cplusplus >= 201103L && defined __clang__ && __clang_major__ + (__clang_minor__ >= 9) > 3))) || (defined __STDC_VERSION__ && __STDC_VERSION__ >= 202000L && ((defined __GNUC__ && __GNUC__ >= 10) || (defined __clang__ && __clang_major__ >= 9)))
      [[fallthrough]];
#elif (defined __GNUC__ && __GNUC__ >= 7) || (defined __clang__ && __clang_major__ >= 10)
      __attribute__ ((__fallthrough__));
#endif
      /*FALLTHROUGH*/
      case 9:
      case 8:
        hval += asso_values[(unsigned char)str[7]];
#if (defined __cplusplus && (__cplusplus >= 201703L || (__cplusplus >= 201103L && defined __clang__ && __clang_major__ + (__clang_minor__ >= 9) > 3))) || (defined __STDC_VERSION__ && __STDC_VERSION__ >= 202000L && ((defined __GNUC__ && __GNUC__ >= 10) || (defined __clang__ && __clang_major__ >= 9)))
      [[fallthrough]];
#elif (defined __GNUC__ && __GNUC__ >= 7) || (defined __clang__ && __clang_major__ >= 10)
      __attribute__ ((__fallthrough__));
#endif
      /*FALLTHROUGH*/
      case 7:
      case 6:
        hval += asso_values[(unsigned char)str[5]];
        break;
    }
  return hval + asso_values[(unsigned char)str[len - 1]];
}

const struct NifNameAndNifPtr *
nif_in_word_set (register const char *str, register size_t len)
{
#if (defined __GNUC__ && __GNUC__ + (__GNUC_MINOR__ >= 6) > 4) || (defined __clang__ && __clang_major__ >= 3)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif
  static const struct NifNameAndNifPtr wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 176 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:exp/1", &math_exp_nif},
      {""}, {""}, {""}, {""},
#line 186 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:tan/1", &math_tan_nif},
      {""}, {""}, {""}, {""},
#line 183 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:sin/1", &math_sin_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
#line 177 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:floor/1", &math_floor_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""},
#line 159 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"maps:from_keys/2", &maps_from_keys_nif},
      {""}, {""}, {""},
#line 122 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:!/2", &send_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
#line 111 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:put/2", &put_nif},
#line 81 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:open_port/2", &open_port_nif},
#line 57 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:error/2", &error_nif},
      {""}, {""}, {""},
#line 60 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:exit/2", &exit_nif},
#line 115 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:throw/1", &throw_nif},
#line 179 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:log/1", &math_log_nif},
      {""}, {""},
#line 59 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:exit/1", &exit_nif},
#line 56 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:error/1", &error_nif},
      {""}, {""}, {""},
#line 92 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:send/2", &send_nif},
#line 76 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_integer/2", &list_to_integer_nif},
      {""},
#line 67 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_atom/1", &list_to_atom_nif},
#line 77 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_float/1", &list_to_float_nif},
      {""},
#line 75 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_integer/1", &list_to_integer_nif},
#line 151 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"code:ensure_loaded/1", &code_ensure_loaded_nif},
      {""},
#line 102 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:tuple_to_list/1", &tuple_to_list_nif},
#line 73 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:link/1", &link_nif},
      {""},
#line 96 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:system_info/1", &system_info_nif},
      {""},
#line 78 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_tuple/1", &list_to_tuple_nif},
#line 114 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:term_to_binary/1", &term_to_binary_nif},
#line 72 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:integer_to_list/2", &integer_to_list_nif},
#line 101 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:system_time/1", &system_time_nif},
#line 70 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:integer_to_binary/2", &integer_to_binary_nif},
      {""}, {""},
#line 71 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:integer_to_list/1", &integer_to_list_nif},
#line 68 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_existing_atom/1", &list_to_existing_atom_nif},
#line 69 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:integer_to_binary/1", &integer_to_binary_nif},
#line 180 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:log10/1", &math_log10_nif},
#line 74 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:list_to_binary/1", &list_to_binary_nif},
      {""},
#line 79 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:iolist_size/1", &iolist_size_nif},
      {""},
#line 65 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:float_to_list/2", &float_to_list_nif},
#line 113 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_term/2", &binary_to_term_nif},
#line 63 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:float_to_binary/2", &float_to_binary_nif},
#line 42 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"calendar:system_time_to_universal_time/2", &system_time_to_universal_time_nif},
#line 110 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:process_info/2", &process_info_nif},
#line 64 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:float_to_list/1", &float_to_list_nif},
#line 112 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_term/1", &binary_to_term_nif},
#line 62 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:float_to_binary/1", &float_to_binary_nif},
#line 80 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:iolist_to_binary/1", &iolist_to_binary_nif},
      {""}, {""}, {""}, {""},
#line 119 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:ref_to_list/1", &ref_to_list_nif},
#line 50 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_integer/2", &binary_to_integer_nif},
#line 53 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_existing_atom/2", &binary_to_existing_atom_nif},
#line 51 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_list/1", &binary_to_list_nif},
      {""}, {""},
#line 49 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_integer/1", &binary_to_integer_nif},
#line 52 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_existing_atom/1", &binary_to_existing_atom_nif},
      {""}, {""},
#line 174 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:cos/1", &math_cos_nif},
      {""},
#line 90 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:register/2", &register_nif},
      {""}, {""},
#line 120 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:fun_to_list/1", &fun_to_list_nif},
#line 185 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:sqrt/1", &math_sqrt_nif},
#line 167 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:acosh/1", &math_acosh_nif},
      {""}, {""}, {""},
#line 126 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:group_leader/2", &group_leader_nif},
      {""},
#line 109 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:processes/0", &processes_nif},
      {""},
#line 182 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:pow/2", &math_pow_nif},
#line 187 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:tanh/1", &math_tanh_nif},
#line 169 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:asinh/1", &math_asinh_nif},
      {""},
#line 48 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_float/1", &binary_to_float_nif},
#line 97 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:system_flag/2", &system_flag_nif},
#line 184 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:sinh/1", &math_sinh_nif},
      {""},
#line 94 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:spawn_opt/2", &spawn_fun_opt_nif},
#line 124 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:garbage_collect/1", &garbage_collect_nif},
      {""},
#line 178 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:fmod/2", &math_fmod_nif},
      {""}, {""},
#line 55 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:erase/1", &erase_nif},
#line 118 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:pid_to_list/1", &pid_to_list_nif},
#line 45 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:atom_to_list/1", &atom_to_list_nif},
      {""},
#line 95 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:spawn_opt/4", &spawn_opt_nif},
#line 40 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:split/2", &binary_split_nif},
#line 155 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"base64:encode_to_string/1", &base64_encode_to_string_nif},
#line 107 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:process_flag/2", &process_flag_nif},
#line 172 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:atan2/2", &math_atan2_nif},
#line 38 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:last/1", &binary_last_nif},
      {""},
#line 158 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"lists:reverse/2", &lists_reverse_nif},
      {""},
#line 103 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:universaltime/0", &universaltime_nif},
#line 44 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:atom_to_binary/2", &atom_to_binary_nif},
      {""},
#line 157 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"lists:reverse/1", &lists_reverse_nif},
#line 125 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:group_leader/0", &group_leader_nif},
      {""},
#line 43 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:atom_to_binary/1", &atom_to_binary_nif},
      {""},
#line 152 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"console:print/1", &console_print_nif},
#line 86 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:monitor/2", &monitor_nif},
      {""}, {""},
#line 123 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:garbage_collect/0", &garbage_collect_nif},
      {""},
#line 144 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_unlink/1", IF_HAVE_UNLINK(&atomvm_posix_unlink_nif)},
#line 146 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_opendir/1", IF_HAVE_OPENDIR_READDIR_CLOSEDIR(&atomvm_posix_opendir_nif)},
      {""}, {""}, {""},
#line 99 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:++/2", &concat_nif},
#line 148 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_readdir/1", IF_HAVE_OPENDIR_READDIR_CLOSEDIR(&atomvm_posix_readdir_nif)},
#line 134 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:read_priv/2", &atomvm_read_priv_nif},
      {""}, {""},
#line 160 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"maps:next/1", &maps_next_nif},
#line 83 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:make_ref/0", &make_ref_nif},
#line 47 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_atom/2", &binary_to_atom_nif},
#line 37 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:first/1", &binary_first_nif},
      {""},
#line 181 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:log2/1", &math_log2_nif},
      {""},
#line 46 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:binary_to_atom/1", &binary_to_atom_nif},
#line 58 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:error/3", &error_nif},
      {""}, {""}, {""},
#line 100 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:monotonic_time/1", &monotonic_time_nif},
#line 116 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:raise/3", &raise_nif},
      {""}, {""}, {""}, {""},
#line 128 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:get_module_info/2", &get_module_info_nif},
      {""},
#line 166 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:acos/1", &math_acos_nif},
      {""},
#line 105 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:localtime/1", &localtime_nif},
#line 127 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:get_module_info/1", &get_module_info_nif},
      {""},
#line 98 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:whereis/1", &whereis_nif},
      {""}, {""}, {""}, {""},
#line 168 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:asin/1", &math_asin_nif},
#line 171 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:atanh/1", &math_atanh_nif},
#line 88 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:demonitor/2", &demonitor_nif},
      {""},
#line 156 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"base64:decode_to_string/1", &base64_decode_to_string_nif},
      {""}, {""},
#line 39 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:part/3", &binary_part_nif},
      {""}, {""},
#line 108 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:process_flag/3", &process_flag_nif},
      {""},
#line 87 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:demonitor/1", &demonitor_nif},
      {""},
#line 89 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:is_process_alive/1", &is_process_alive_nif},
#line 121 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:function_exported/3", &function_exported_nif},
      {""}, {""},
#line 135 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_open/2", IF_HAVE_OPEN_CLOSE(&atomvm_posix_open_nif)},
#line 149 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"code:load_abs/1", &code_load_abs_nif},
#line 143 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_mkfifo/2", IF_HAVE_MKFIFO(&atomvm_posix_mkfifo_nif)},
#line 129 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erts_debug:flat_size/1", &flat_size_nif},
#line 145 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_clock_settime/2", IF_HAVE_CLOCK_SETTIME_OR_SETTIMEOFDAY(&atomvm_posix_clock_settime_nif)},
#line 138 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_read/2", IF_HAVE_OPEN_CLOSE(&atomvm_posix_read_nif)},
#line 137 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_close/1", IF_HAVE_OPEN_CLOSE(&atomvm_posix_close_nif)},
      {""}, {""},
#line 147 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_closedir/1", IF_HAVE_OPENDIR_READDIR_CLOSEDIR(&atomvm_posix_closedir_nif)},
      {""},
#line 117 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:unlink/1", &unlink_nif},
#line 142 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_select_stop/1", IF_HAVE_OPEN_CLOSE(&atomvm_posix_select_stop_nif)},
      {""},
#line 54 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:delete_element/2", &delete_element_nif},
#line 91 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:unregister/1", &unregister_nif},
      {""},
#line 175 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:cosh/1", &math_cosh_nif},
      {""},
#line 66 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:insert_element/3", &insert_element_nif},
      {""},
#line 139 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_write/2", IF_HAVE_OPEN_CLOSE(&atomvm_posix_write_nif)},
#line 173 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:ceil/1", &math_ceil_nif},
      {""},
#line 133 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:get_start_beam/1", &atomvm_get_start_beam_nif},
      {""},
#line 153 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"base64:encode/1", &base64_encode_nif},
      {""}, {""}, {""}, {""}, {""}, {""},
#line 82 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:make_fun/3", &make_fun_nif},
#line 104 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:localtime/0", &localtime_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 36 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:copy/2", &binary_copy_nif},
      {""}, {""}, {""}, {""},
#line 35 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:copy/1", &binary_copy_nif},
      {""}, {""},
#line 61 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:display/1", &display_nif},
      {""},
#line 162 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"unicode:characters_to_list/2", &unicode_characters_to_list_nif},
      {""},
#line 164 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"unicode:characters_to_binary/2", &unicode_characters_to_binary_nif},
      {""}, {""},
#line 161 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"unicode:characters_to_list/1", &unicode_characters_to_list_nif},
#line 41 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:split/3", &binary_split_nif},
#line 163 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"unicode:characters_to_binary/1", &unicode_characters_to_binary_nif},
#line 170 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"math:atan/1", &math_atan_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 136 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_open/3", IF_HAVE_OPEN_CLOSE(&atomvm_posix_open_nif)},
      {""}, {""}, {""},
#line 106 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:timestamp/0", &timestamp_nif},
      {""}, {""},
#line 140 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_select_read/3", IF_HAVE_OPEN_CLOSE(&atomvm_posix_select_read_nif)},
#line 141 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:posix_select_write/3", IF_HAVE_OPEN_CLOSE(&atomvm_posix_select_write_nif)},
      {""}, {""}, {""}, {""}, {""},
#line 132 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:close_avm_pack/2", &atomvm_close_avm_pack_nif},
      {""}, {""}, {""}, {""}, {""}, {""},
#line 154 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"base64:decode/1", &base64_decode_nif},
      {""}, {""},
#line 150 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"code:load_binary/3", &code_load_binary_nif},
      {""}, {""}, {""}, {""}, {""},
#line 84 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:make_tuple/2", &make_tuple_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""},
#line 93 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:setelement/3", &setelement_nif},
#line 165 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"unicode:characters_to_binary/3", &unicode_characters_to_binary_nif},
#line 34 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"binary:at/2", &binary_at_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
#line 85 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"erlang:memory/1", &memory_nif},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
#line 131 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:add_avm_pack_file/2", &atomvm_add_avm_pack_file_nif},
      {""},
#line 130 "/tmp/atomvm-inspect/src/libAtomVM/nifs.gperf"
      {"atomvm:add_avm_pack_binary/2", &atomvm_add_avm_pack_binary_nif}
    };
#if (defined __GNUC__ && __GNUC__ + (__GNUC_MINOR__ >= 6) > 4) || (defined __clang__ && __clang_major__ >= 3)
#pragma GCC diagnostic pop
#endif

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        {
          register const char *s = wordlist[key].name;

          if (*str == *s && !strcmp (str + 1, s + 1))
            return &wordlist[key];
        }
    }
  return (struct NifNameAndNifPtr *) 0;
}
