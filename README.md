
# MenuNest 🍽️

**MenuNest** is a digital menu platform designed to help restaurants, school cafeterias, and other food businesses manage and display their menus online.

The platform is designed to support multiple restaurants, with each restaurant managing its own menu.

## 🚀 Project Goals

- Allow different restaurants and school cafeterias to register.
- Display food menus online.
- Allow restaurant owners to manage dishes and prices.
- Support QR codes that customers can scan to open a restaurant's menu.
- Provide a foundation for future online food ordering and payments.
- Support expansion to multiple restaurants and schools.

## ✨ Planned Features

- [x] Initial website interface
- [x] Supabase database setup script
- [x] Restaurant and dish database structure
- [ ] User registration and login
- [ ] Restaurant registration and approval
- [ ] Restaurant owner dashboard
- [ ] Add, edit, and delete dishes
- [ ] Upload food images
- [ ] Public restaurant menu pages
- [ ] QR code generation for each restaurant
- [ ] Online food ordering
- [ ] Payment integration
- [ ] School and cafeteria management

> Note: Features listed as incomplete still need to be implemented and tested.

## 🛠️ Technologies

- **HTML** — website structure
- **CSS** — website styling
- **JavaScript** — website functionality
- **Supabase** — database, authentication, and access control
- **GitHub** — source code management
- **Render** — website hosting

## 📁 Project Structure

```text
menunest/
├── index.html
├── setup.sql
└── README.md
```

## ⚙️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/menunest.git
cd menunest
```

Replace `YOUR-USERNAME` with your GitHub username.

### 2. Set Up Supabase

1. Create a project at https://supabase.com/
2. Open the project's SQL Editor.
3. Create a new query.
4. Copy the contents of `setup.sql` into the editor.
5. Run the SQL script.
6. Check that the `restaurants` and `dishes` tables exist.

If the tables and policies have already been created, review the existing setup before rerunning the script.

### 3. Configure the Website

To connect the website to Supabase, configure the project URL and publishable key in the frontend code.

Use the Supabase project URL and publishable key only. Never put a Supabase service-role key or other secret key in public website code.

The frontend must also implement the required Supabase queries and authentication before database features will work.

### 4. Run the Website

Open `index.html` in a browser to view the initial interface.

For deployment, connect the GitHub repository to a static website hosting service such as Render.

## 🗄️ Database Overview

### Restaurants

Stores restaurant information, including:

- Restaurant name
- Owner account
- Unique menu slug
- Description and logo
- Approval status
- Creation date

### Dishes

Stores menu items, including:

- Dish name
- Description
- Price
- Food image
- Category
- Availability
- Associated restaurant

Row Level Security (RLS) policies are intended to restrict restaurant owners to managing their own restaurant data.

## 🔐 Security

- Use Supabase Row Level Security (RLS).
- Require authentication for restaurant management.
- Restrict restaurant approval to an authorized administrator.
- Keep secret keys on a secure server, never in frontend code.
- Test access policies before launching publicly.

## 🌍 Deployment

MenuNest can be hosted using Render Static Sites and connected to a GitHub repository.

Every code change committed to the configured branch can trigger a new deployment, depending on the hosting settings.

## 📌 Current Status

MenuNest is under development. The initial interface and database setup are the foundation for a multi-restaurant platform. Authentication, owner dashboards, live database integration, QR code generation, ordering, and payment functionality require further development and testing.

## 📄 License

This project does not yet specify a license. Add a license before allowing others to reuse or distribute the code.

---

**MenuNest — One platform, many menus.**
