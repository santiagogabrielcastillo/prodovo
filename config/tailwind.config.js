const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.{js,ts}",
    "./app/views/**/*.{erb,html}",
    "./app/views/layouts/pdf.html.erb", // Explicitly include PDF layout
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

