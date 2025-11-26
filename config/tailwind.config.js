const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.{js,ts}",
    "./app/views/**/*.{erb,html}",
    "./config/initializers/**/*.rb"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", ...defaultTheme.fontFamily.sans]
      }
    }
  },
  plugins: [
    require("@tailwindcss/forms")
  ]
}

