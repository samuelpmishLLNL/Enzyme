#pragma once

/////////////
// tuple.h //
/////////////

// why reinvent the wheel and implement a tuple class?
//  - ensure data is laid out in the same order the types are specified
//        see: https://github.com/EnzymeAD/Enzyme/issues/1191#issuecomment-1556239213
//  - CUDA compatibility: std::tuple has some compatibility issues when used
//        in a __device__ context (this may get better in c++20 with the improved
//        constexpr support for std::tuple). Owning the implementation lets
//        us add __host__ __device__ annotations to any part of it

#include <utility> // for std::integer_sequence

#include "type_traits.h"

namespace enzyme {

template <int i>
struct Index {};

template <int i, typename T>
struct value_at_position { 
  __attribute__((always_inline))
  constexpr T & operator[](Index<i>) { return value; }

  __attribute__((always_inline))
  constexpr const T & operator[](Index<i>) const { return value; }
  T value;
};

template <typename S, typename... T>
struct tuple_base;

template <int... i, typename... T>
struct tuple_base<std::integer_sequence<int, i...>, T...>
    : public value_at_position<i, T>... {
    using value_at_position<i, T>::operator[]...;
}; 

template <typename... T>
struct tuple : public tuple_base<std::make_integer_sequence<int, sizeof...(T)>, T...> {};

template <typename... T>
tuple(T ...) -> tuple<T...>;

template < int i, typename Tuple >
__attribute__((always_inline))
decltype(auto) get(Tuple && tup) {
  constexpr bool is_lvalue = std::is_lvalue_reference_v<Tuple>;
  constexpr bool is_const = std::is_const_v<std::remove_reference_t<Tuple>>;
  using T = remove_cvref_t< decltype(tup[Index<i>{}]) >;
  if constexpr ( is_lvalue &&  is_const) { return static_cast<const T&>(tup[Index<i>{}]); }
  if constexpr ( is_lvalue && !is_const) { return static_cast<T&>(tup[Index<i>{}]); }
  if constexpr (!is_lvalue &&  is_const) { return static_cast<const T&&>(tup[Index<i>{}]); }
  if constexpr (!is_lvalue && !is_const) { return static_cast<T&&>(tup[Index<i>{}]); }
}

template < int i, typename ... T>
__attribute__((always_inline))
decltype(auto) get(const tuple< T ... > & tup) {
    return tup[Index<i>{}];
}

template <typename Tuple>
struct tuple_size;

template <typename... T>
struct tuple_size<tuple<T...>> : std::integral_constant<size_t, sizeof...(T)> {};

template <typename Tuple>
static constexpr size_t tuple_size_v = tuple_size<Tuple>::value;

template <typename T>
__attribute__((always_inline))
auto forward(std::remove_reference_t<T>& arg) _NOEXCEPT {
  return static_cast<T&&>(arg);
}

template <typename T>
__attribute__((always_inline))
auto forward(std::remove_reference_t<T>&& arg) _NOEXCEPT {
  static_assert(!std::is_lvalue_reference<T>::value, "cannot forward an rvalue as an lvalue");
  return static_cast<T&&>(arg);
}

template <typename... T>
__attribute__((always_inline))
constexpr auto forward_as_tuple(T&&... args) noexcept {
  return tuple<T&&...>{forward<T>(args)...};
}

namespace impl {

template <typename index_seq>
struct make_tuple_from_fwd_tuple;

template <size_t... indices>
struct make_tuple_from_fwd_tuple<std::index_sequence<indices...>> {
  template <typename FWD_TUPLE>
  __attribute__((always_inline))
  static constexpr auto f(FWD_TUPLE&& fwd) {
    return tuple{get<indices>(forward<FWD_TUPLE>(fwd))...};
  }
};

template <typename FWD_INDEX_SEQ, typename TUPLE_INDEX_SEQ>
struct concat_with_fwd_tuple;

template < typename Tuple >
using iseq = std::make_index_sequence<tuple_size_v< enzyme::remove_cvref_t< Tuple > > >;

template <size_t... fwd_indices, size_t... indices>
struct concat_with_fwd_tuple<std::index_sequence<fwd_indices...>, std::index_sequence<indices...>> {
  template <typename FWD_TUPLE, typename TUPLE>
  __attribute__((always_inline))
  static constexpr auto f(FWD_TUPLE&& fwd, TUPLE&& t) {
    return forward_as_tuple(get<fwd_indices>(forward<FWD_TUPLE>(fwd))..., get<indices>(std::forward<TUPLE>(t))...);
  }
};

template <typename Tuple>
__attribute__((always_inline))
static constexpr auto tuple_cat(Tuple&& ret) {
  return make_tuple_from_fwd_tuple< iseq< Tuple > >::f(forward< Tuple >(ret));
}

template <typename FWD_TUPLE, typename first, typename... rest>
__attribute__((always_inline))
static constexpr auto tuple_cat(FWD_TUPLE&& fwd, first&& t, rest&&... ts) {
  return tuple_cat(concat_with_fwd_tuple< iseq<FWD_TUPLE>, iseq<first> >::f(forward<FWD_TUPLE>(fwd), std::forward<first>(t)), std::forward<rest>(ts)...);
}

}  // namespace impl

template <typename... Tuples>
__attribute__((always_inline))
constexpr auto tuple_cat(Tuples&&... tuples) {
  return impl::tuple_cat(std::forward<Tuples>(tuples)...);
}

} // namespace enzyme