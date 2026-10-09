
const express = require("express");
const cors = require("cors");
const { createClient } = require("@supabase/supabase-js");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "1mb" }));

// Supabase configuration.
// Use the publishable key, never a service-role key, here.
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

const supabase =
  supabaseUrl && supabaseKey
    ? createClient(supabaseUrl, supabaseKey)
    : null;

// Basic error responses
function databaseRequired(req, res, next) {
  if (!supabase) {
    return res.status(503).json({
      error: "Supabase is not configured. Set the environment variables."
    });
  }
  next();
}

// Homepage / API information
app.get("/", (req, res) => {
  res.json({
    name: "MenuNest API",
    status: "running",
    endpoints: [
      "GET /api/health",
      "GET /api/restaurants",
      "GET /api/restaurants/:slug",
      "GET /api/restaurants/:slug/dishes"
    ]
  });
});

// Health check
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    databaseConfigured: Boolean(supabase)
  });
});

// List approved restaurants
app.get("/api/restaurants", databaseRequired, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("restaurants")
      .select("id, name, slug, description, logo_url")
      .eq("status", "approved")
      .order("name", { ascending: true });

    if (error) throw error;

    res.json({ restaurants: data });
  } catch (error) {
    console.error("Failed to fetch restaurants:", error.message);
    res.status(500).json({ error: "Unable to load restaurants." });
  }
});

// Get one approved restaurant by its URL slug
app.get(
  "/api/restaurants/:slug",
  databaseRequired,
  async (req, res) => {
    try {
      const { data, error } = await supabase
        .from("restaurants")
        .select("id, name, slug, description, logo_url")
        .eq("slug", req.params.slug)
        .eq("status", "approved")
        .maybeSingle();

      if (error) throw error;

      if (!data) {
        return res.status(404).json({ error: "Restaurant not found." });
      }

      res.json({ restaurant: data });
    } catch (error) {
      console.error("Failed to fetch restaurant:", error.message);
      res.status(500).json({ error: "Unable to load restaurant." });
    }
  }
);

// Get available dishes for an approved restaurant
app.get(
  "/api/restaurants/:slug/dishes",
  databaseRequired,
  async (req, res) => {
    try {
      const { data: restaurant, error: restaurantError } =
        await supabase
          .from("restaurants")
          .select("id, name, slug, description, logo_url")
          .eq("slug", req.params.slug)
          .eq("status", "approved")
          .maybeSingle();

      if (restaurantError) throw restaurantError;

      if (!restaurant) {
        return res.status(404).json({ error: "Restaurant not found." });
      }

      const { data: dishes, error: dishesError } = await supabase
        .from("dishes")
        .select("id, name, description, price, image_url, category")
        .eq("restaurant_id", restaurant.id)
        .eq("available", true)
        .order("category", { ascending: true })
        .order("name", { ascending: true });

      if (dishesError) throw dishesError;

      res.json({ restaurant, dishes });
    } catch (error) {
      console.error("Failed to fetch dishes:", error.message);
      res.status(500).json({ error: "Unable to load menu." });
    }
  }
);

// Unknown API endpoints
app.use("/api", (req, res) => {
  res.status(404).json({ error: "API endpoint not found." });
});

// General error handler
app.use((error, req, res, next) => {
  console.error("Server error:", error.message);
  res.status(500).json({ error: "An unexpected server error occurred." });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`MenuNest API listening on port ${PORT}`);
});
