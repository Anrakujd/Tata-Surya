import java.util.HashMap;

// =======================================================
// FINAL PROCESSING SKETCH - INTERACTIVE SOLAR SYSTEM
// Dengan Informasi Planet Berbeda Saat Diklik
// dibuat oleh Irfansius dan Michael
// pembimbing : Djukarna
// Prodi pendidikan TIK FKIP UNPAR, Bandung.
// =======================================================

// === Kamera & Zoom ===
float perbesaran = 1200;
float perbesaran_minimal = 400;
float perbesaran_maximal = 6000;

float rotasi_X = 0;
float rotasi_Y = 0;

float posisi_mouse_sebelum_X, posisi_mouse_sebelum_Y;
boolean sedang_menarik = false;

// === Efek Bintang ===
PVector[] bintang;
int jumlah_total_bintang = 400;

// === Tekstur Matahari ===
PShape matahari;
PImage textur_matahari;

// === Tekstur Cincin Saturnus ===
PImage textur_cincin;

// === PANEL INFORMASI ===
boolean panel_aktif = false;
String planet_diklik = "";
float panel_width = 620;
float panel_height = 300;

// === Panel Animasi Slide ===
float panel_posX;         
float panel_targetX;      
float panel_speed = 0.15; 

// posisi layar matahari
float sun_sx = 0, sun_sy = 0;
float sun_radius_screen = 50;

// =======================================================
// === INFO PLANET (FITUR BARU) ===
// =======================================================
HashMap<String, String[]> infoPlanet = new HashMap<String, String[]>();

// === Kelas Planet ===
class daftar_planet {
    String nama;
    float jarak_orbit;
    float ukuran_visual;
    float sudut;
    float orbit_eksentrisitas;
    float kemiringan_orbit;
    float kecepatan_orbit;
    float sudut_rotasi = 0;
    float kecepatan_rotasi;
    float kecepatan_rotasi1;
    PShape bentuk_bola;

    boolean punya_cincin = false;
    PShape cincin;

    float px, py, pz;
    float sx, sy;

    daftar_planet(String nama, float jarak_orbit, float ukuran_visual, String berkas_textur,
                  float orbit_eksentrisitas, float kemiringan_orbit, float kecepatan_orbit,
                  float kecepatan_rotasi, float kecepatan_rotasi1) 
    {
        this.nama = nama;
        this.jarak_orbit = jarak_orbit;
        this.ukuran_visual = ukuran_visual;
        this.sudut = random(TWO_PI);
        this.orbit_eksentrisitas = orbit_eksentrisitas;
        this.kemiringan_orbit = kemiringan_orbit;
        this.kecepatan_orbit = kecepatan_orbit;
        this.kecepatan_rotasi = kecepatan_rotasi;
        this.kecepatan_rotasi1 = kecepatan_rotasi1;

        PImage gambar_textur = loadImage(berkas_textur);
        bentuk_bola = createShape(SPHERE, ukuran_visual);

        if (gambar_textur != null) bentuk_bola.setTexture(gambar_textur);
        else bentuk_bola.setFill(color(200));

        bentuk_bola.setStroke(false);
    }

    void tambah_cincin(PImage textur_cincin, float jari_dalam, float jari_luar) {
        punya_cincin = true;
        cincin = createShape();
        cincin.beginShape(QUAD_STRIP);
        cincin.texture(textur_cincin);
        cincin.noStroke();

        int detail = 80;
        for (int i = 0; i <= detail; i++) {
            float sud = TWO_PI * i / detail;
            float x1 = cos(sud) * jari_dalam;
            float y1 = sin(sud) * jari_dalam;
            float x2 = cos(sud) * jari_luar;
            float y2 = sin(sud) * jari_luar;
            float u = map(i, 0, detail, 0, 1);
            cincin.vertex(x1, y1, 0, u, 0);
            cincin.vertex(x2, y2, 0, u, 1);
        }
        cincin.endShape();
    }

    void pembaharuan() {
        sudut += kecepatan_orbit;
        sudut_rotasi += kecepatan_rotasi1;

        float a = jarak_orbit;
        float b = a * sqrt(max(0, 1 - orbit_eksentrisitas*orbit_eksentrisitas));

        px = a * cos(sudut);
        pz = b * sin(sudut);
        py = 0;
    }

    void display() {
        pushMatrix();

        // gambar orbit
        pushMatrix();
        rotateX(HALF_PI);
        noFill();
        stroke(180, 180);
        strokeWeight(map(jarak_orbit, 100, 900, 1.5, 3.0));
        ellipse(0, 0, jarak_orbit*2, jarak_orbit*2*(1-orbit_eksentrisitas));
        popMatrix();

        translate(px, py, pz);
        rotateY(sudut_rotasi);

        // SIMPAN posisi layar planet
        sx = screenX(0, 0, 0);
        sy = screenY(0, 0, 0);

        shape(bentuk_bola);

        if (punya_cincin && cincin != null) {
            pushMatrix();
            rotateX(HALF_PI);
            shape(cincin);
            popMatrix();
        }
        popMatrix();
    }
}

daftar_planet[] planet;

void setup() {
    size(1200, 800, P3D);
    surface.setResizable(true);
    textFont(createFont("Arial", 14));
    smooth(8);

    // Panel animasi
    panel_posX = width;
    panel_targetX = width;

    // Bintang
    bintang = new PVector[jumlah_total_bintang];
    for (int i = 0; i < jumlah_total_bintang; i++) {
        bintang[i] = new PVector(random(-4000, 4000), random(-4000, 4000), random(-4000, 4000));
    }

    // Tekstur matahari
    textur_matahari = loadImage("matahari.jpg");
    matahari = createShape(SPHERE, 70);

    if (textur_matahari != null) matahari.setTexture(textur_matahari);
    else matahari.setFill(color(255, 204, 0));

    matahari.setStroke(false);

    // Tekstur cincin Saturnus
    textur_cincin = loadImage("saturnus_cincin.png");

    // =======================================================
    // ISI INFORMASI PLANET (FITUR BARU)
    // =======================================================
    infoPlanet.put("Matahari", new String[]{
        "Bintang pusat tata surya",
        "Suhu permukaan 5500°C",
        "Diameter 1.39 juta km"
    });

    infoPlanet.put("Merkurius", new String[]{
        "Planet terkecil",
        "Tidak punya atmosfer tebal",
        "Terdekat dengan Matahari"
    });

    infoPlanet.put("Venus", new String[]{
        "Planet terpanas",
        "Atmosfer CO₂ super tebal",
        "Rotasi berlawanan arah"
    });

    infoPlanet.put("Bumi", new String[]{
        "Satu-satunya planet berpenghuni",
        "70% tertutup air",
        "Satelit: Bulan",
        "Irfansius Laia adalah ultraman"
    });

    infoPlanet.put("Mars", new String[]{
        "Dikenal sebagai Planet Merah",
        "Gunung Olympus Mons terbesar",
        "Kandidat koloni manusia"
    });

    infoPlanet.put("Jupiter", new String[]{
        "Planet terbesar",
        "Memiliki Bintik Merah Besar",
        "Gas raksasa"
    });

    infoPlanet.put("Saturnus", new String[]{
        "Dikenal karena cincinnya",
        "Gas raksasa",
        "Lebih ringan dari air"
    });

    infoPlanet.put("Uranus", new String[]{
        "Berputar miring 98°",
        "Planet es raksasa",
        "Biru pucat"
    });

    infoPlanet.put("Neptunus", new String[]{
        "Angin tercepat di tata surya",
        "Planet es raksasa",
        "Biru gelap"
    });

    infoPlanet.put("Pluto", new String[]{
        "Planet katai",
        "Orbit sangat elips",
        "Sangat dingin"
    });

    // Planet
    planet = new daftar_planet[]{
        new daftar_planet("Merkurius", 100, 20, "merkurius.jpg", 0, 0, 0.00040, 0.02, 0.0009),
        new daftar_planet("Venus", 180, 28, "venus.jpg", 0, 0, 0.00025, 0.01, 0.0008),
        new daftar_planet("Bumi", 260, 30, "bumi.jpg", 0, 0, 0.0002, 0.01, 0.0008),
        new daftar_planet("Mars", 340, 26, "mars.jpg", 0, 0, 0.00015, 0.02, 0.0007),
        new daftar_planet("Jupiter", 420, 52, "jupiter.jpg", 0, 0, 0.0001, 0.04, 0.0008),
        new daftar_planet("Saturnus", 520, 46, "saturnus.jpg", 0, 0, 0.00005, 0.03, 0.0009),
        new daftar_planet("Uranus", 700, 38, "uranus.jpg", 0, 0, 0.00007, 0.04, 0.0007),
        new daftar_planet("Neptunus", 820, 38, "neptunus.jpg", 0, 0, 0.00008, 0.03, 0.0008),
        new daftar_planet("Pluto", 900, 14, "pluto.jpg", 0.25, 50, 0.00009, 0.02, 0.0009),
    };

    // Cincin Saturnus
    planet[5].tambah_cincin(textur_cincin, 60, 100);
}

void draw() {
    background(0);

    // bintang
    pushMatrix();
    translate(width/2, height/2, 0);
    rotateX(rotasi_X);
    rotateY(rotasi_Y);

    stroke(255);
    strokeWeight(2);
    for (PVector t : bintang) {
        point(t.x, t.y, t.z);
    }
    popMatrix();

    // cahaya
    lights();
    directionalLight(255, 255, 255, -1, 0, 0);

    camera(width/2.0, height/2.0, perbesaran,
           width/2.0, height/2.0, 0, 0, 1, 0);

    translate(width/2, height/2, 0);
    rotateX(rotasi_X);
    rotateY(rotasi_Y);

    // Matahari
    pushMatrix();
    noStroke();
    shape(matahari);

    sun_sx = screenX(0, 0, 0);
    sun_sy = screenY(0, 0, 0);

    PVector edge = new PVector(70, 0, 0);
    float edge_sx = screenX(edge.x, edge.y, edge.z);
    sun_radius_screen = abs(edge_sx - sun_sx);
    popMatrix();

    // Planet
    for (daftar_planet p : planet) {
        p.pembaharuan();
        p.display();
    }

    // HUD
    hint(DISABLE_DEPTH_TEST);
    camera();
    fill(255);

    PFont fontTebal = createFont("Times New Roman", 20);
    textFont(fontTebal);

    textAlign(CENTER);
    text("KARYA MIKHAEL MENTODION NDRAHA & IRFANSIUS LAIA", width/2, height - 15);

    textSize(25);
    textAlign(CENTER);
    text("HANYA MODEL, BUKAN UKURAN SEBENARNYA", width/2, 35);

    textSize(20);

    hint(ENABLE_DEPTH_TEST);

    // tampilkan panel dengan animasi slide
    tampilkanPanel();
}

// =======================================================
// PANEL INFORMASI (FITUR BARU) - versi animasi slide
// =======================================================
void tampilkanPanel() {
    hint(DISABLE_DEPTH_TEST);
    camera();

    // --- Tentukan target slide ---
    if (panel_aktif) {
        panel_targetX = width - panel_width - 20; // posisi terbuka
    } else {
        panel_targetX = width + 50; // sembunyikan keluar layar
    }

    // --- ANIMASI SLIDE ---
    panel_posX = lerp(panel_posX, panel_targetX, panel_speed);

    // --- Gambar panel ---
    fill(30, 30, 30, 240);
    rect(panel_posX, 20, panel_width, panel_height, 15);

    fill(255);
    textAlign(LEFT);
    textSize(26);
    text("Informasi: " + planet_diklik, panel_posX + 10, 60);

    textSize(18);
    if (infoPlanet.containsKey(planet_diklik)) {
        String[] data = infoPlanet.get(planet_diklik);

        int y = 110;
        for (String s : data) {
            text("- " + s, panel_posX + 10, y);
            y += 30;
        }
    }

    // --- Tombol X ---
    fill(200, 50, 50);
    rect(panel_posX + panel_width - 50, 20, 40, 40, 10);

    fill(255);
    textAlign(CENTER);
    textSize(24);
    text("X", panel_posX + panel_width - 30, 50);

    hint(ENABLE_DEPTH_TEST);
}

// =======================================================
// INPUT MOUSE
// =======================================================
void mousePressed() {
    sedang_menarik = true;
    posisi_mouse_sebelum_X = mouseX;
    posisi_mouse_sebelum_Y = mouseY;

    // Tutup panel jika klik tombol X
    if (panel_aktif && mouseX > panel_posX + panel_width - 50 && mouseX < panel_posX + panel_width - 10 &&
        mouseY > 20 && mouseY < 60) 
    {
        panel_aktif = false;
        return;
    }

    // --- Klik Matahari ---
    float dSun = dist(mouseX, mouseY, sun_sx, sun_sy);
    if (dSun < sun_radius_screen + 6) {
        planet_diklik = "Matahari";
        panel_aktif = true;
        return;
    }

    // --- Klik Planet ---
    for (daftar_planet p : planet) {
        if (dist(mouseX, mouseY, p.sx, p.sy) < p.ukuran_visual + 10) {
            planet_diklik = p.nama;
            panel_aktif = true;  // pastiin panel tetap aktif
            return;
        }
    }
}


void mouseDragged() {
    if (sedang_menarik) {
        float dx = radians(mouseX - posisi_mouse_sebelum_X);
        float dy = radians(mouseY - posisi_mouse_sebelum_Y);

        rotasi_Y += dx;
        rotasi_X += dy;

        posisi_mouse_sebelum_X = mouseX;
        posisi_mouse_sebelum_Y = mouseY; 
    }
}

void mouseReleased() {
    sedang_menarik = false;
}

void mouseWheel(MouseEvent event) {
    float arah_scroll = event.getCount();
    perbesaran += arah_scroll * 40;
    perbesaran = constrain(perbesaran, perbesaran_minimal, perbesaran_maximal);
}
