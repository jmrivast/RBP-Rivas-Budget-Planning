class Breakpoints {
  static const mobileMax = 599.0;
  static const tabletMax = 1023.0;

  static bool isMobile(double width) => width <= mobileMax;
  static bool isTablet(double width) => width > mobileMax && width <= tabletMax;
  static bool isDesktop(double width) => width > tabletMax;
}
