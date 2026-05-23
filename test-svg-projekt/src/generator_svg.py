#!/usr/bin/env python3
"""
SVG Graphics Generator & Converter
==================================
Moduł do generowania tła certyfikatów/reklam oraz konwersji JPG na SVG.

Autor: Template Generator
Wersja: 1.0.0
"""

import argparse
import sys
import math
from pathlib import Path
from typing import Optional, Tuple, List

try:
    import svgwrite
except ImportError:
    print("❌ Błąd: Brak biblioteki 'svgwrite'. Zainstaluj: pip install svgwrite")
    sys.exit(1)

try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("⚠️  Uwaga: Brak biblioteki 'Pillow'. Konwersja JPG->SVG będzie ograniczona.")


class SVGCertificateBackground:
    """Generator ozdobnego tła dla certyfikatów."""
    
    def __init__(self, width: int = 1920, height: int = 1080):
        self.width = width
        self.height = height
        self.dwg = svgwrite.Drawing(
            size=(f"{width}px", f"{height}px"),
            viewBox=f"0 0 {width} {height}"
        )
        
    def add_border(self, color: str = "#1a5f7a", width: float = 8.0, 
                   inner_offset: float = 20.0) -> 'SVGCertificateBackground':
        """Dodaje ozdobną ramkę."""
        # Zewnętrzna ramka
        self.dwg.add(self.dwg.rect(
            insert=(width/2, width/2),
            size=(self.width - width, self.height - width),
            fill="none",
            stroke=color,
            stroke_width=width
        ))
        
        # Wewnętrzna ramka
        inner_w = width * 0.4
        offset = inner_offset + width
        self.dwg.add(self.dwg.rect(
            insert=(offset + inner_w/2, offset + inner_w/2),
            size=(self.width - 2*offset - inner_w, self.height - 2*offset - inner_w),
            fill="none",
            stroke=color,
            stroke_width=inner_w,
            opacity=0.6
        ))
        
        return self
    
    def add_corner_elements(self, color: str = "#1a5f7a", 
                           size: float = 80.0) -> 'SVGCertificateBackground':
        """Dodaje ozdobne elementy w rogach."""
        corner_paths = [
            # Lewy górny róg
            f"M {size} 0 L 0 0 L 0 {size}",
            # Prawy górny róg
            f"M {self.width - size} 0 L {self.width} 0 L {self.width} {size}",
            # Lewy dolny róg
            f"M 0 {self.height - size} L 0 {self.height} L {size} {self.height}",
            # Prawy dolny róg
            f"M {self.width} {self.height - size} L {self.width} {self.height} L {self.width - size} {self.height}"
        ]
        
        for path_data in corner_paths:
            self.dwg.add(self.dwg.path(
                d=path_data,
                fill="none",
                stroke=color,
                stroke_width=3.0,
                stroke_linecap="round"
            ))
            
            # Dodatkowa linia ozdobna
            self.dwg.add(self.dwg.path(
                d=path_data,
                fill="none",
                stroke=color,
                stroke_width=1.0,
                stroke_linecap="round",
                transform=f"translate({size * 0.15}, {size * 0.15})" if "0 0" in path_data else 
                         f"translate(-{size * 0.15}, {size * 0.15})" if f"{self.width} 0" in path_data else
                         f"translate({size * 0.15}, -{size * 0.15})" if f"0 {self.height}" in path_data else
                         f"translate(-{size * 0.15}, -{size * 0.15})"
            ))
        
        return self
    
    def add_decorative_pattern(self, pattern_type: str = "circles",
                               color: str = "#1a5f7a",
                               opacity: float = 0.05) -> 'SVGCertificateBackground':
        """Dodaje dekoracyjny wzór w tle."""
        
        if pattern_type == "circles":
            # Wzór kółek
            radius = 60
            spacing = 120
            for x in range(-radius, self.width + radius, spacing):
                for y in range(-radius, self.height + radius, spacing):
                    self.dwg.add(self.dwg.circle(
                        center=(x, y),
                        r=radius * 0.4,
                        fill=color,
                        opacity=opacity
                    ))
                    
        elif pattern_type == "lines":
            # Wzór linii ukośnych
            line_count = 30
            for i in range(line_count):
                offset = i * (self.width + self.height) / line_count
                self.dwg.add(self.dwg.line(
                    start=(-offset, 0),
                    end=(self.height - offset, self.height),
                    stroke=color,
                    stroke_width=1.0,
                    opacity=opacity * 0.5
                ))
                
        elif pattern_type == "geometric":
            # Wzór geometryczny - romby
            diamond_size = 40
            for row in range(int(self.height / diamond_size) + 2):
                for col in range(int(self.width / diamond_size) + 2):
                    cx = col * diamond_size + (row % 2) * diamond_size / 2
                    cy = row * diamond_size * 0.866
                    points = f"{cx},{cy-diamond_size/2} {cx+diamond_size/2},{cy} {cx},{cy+diamond_size/2} {cx-diamond_size/2},{cy}"
                    self.dwg.add(self.dwg.polygon(
                        points=points,
                        fill="none",
                        stroke=color,
                        stroke_width=0.5,
                        opacity=opacity * 0.8
                    ))
        
        return self
    
    def add_gradient_background(self, colors: List[str] = None) -> 'SVGCertificateBackground':
        """Dodaje gradientowe tło."""
        if colors is None:
            colors = ["#fefefe", "#f5f9fa"]
            
        # Definicja gradientu
        gradient = self.dwg.linearGradient(
            start=(0, 0), 
            end=(0, self.height),
            id="bgGradient"
        )
        
        for i, color in enumerate(colors):
            gradient.add_stop_color(offset=f"{i * 100 / (len(colors) - 1)}%", color=color)
        
        self.dwg.defs.add(gradient)
        
        # Tło z gradientem
        self.dwg.add(self.dwg.rect(
            insert=(0, 0),
            size=(self.width, self.height),
            fill="url(#bgGradient)"
        ))
        
        return self
    
    def save(self, filename: str) -> str:
        """Zapisuje plik SVG."""
        output_path = Path(filename)
        if not output_path.suffix.lower() == '.svg':
            output_path = output_path.with_suffix('.svg')
        
        self.dwg.saveas(str(output_path))
        return str(output_path)
    
    def generate(self, output_file: str, 
                 border_color: str = "#1a5f7a",
                 pattern_type: str = "circles",
                 with_corners: bool = True) -> str:
        """Generuje kompletne tło certyfikatu."""
        self.add_gradient_background()
        self.add_decorative_pattern(pattern_type=pattern_type)
        self.add_border(color=border_color)
        
        if with_corners:
            self.add_corner_elements(color=border_color)
            
        return self.save(output_file)


class SVGAdvertisementBackground:
    """Generator tła dla reklam/banerów."""
    
    def __init__(self, width: int = 1920, height: int = 1080):
        self.width = width
        self.height = height
        self.dwg = svgwrite.Drawing(
            size=(f"{width}px", f"{height}px"),
            viewBox=f"0 0 {width} {height}"
        )
        
    def add_modern_gradient(self, colors: List[str] = None,
                            direction: str = "diagonal") -> 'SVGAdvertisementBackground':
        """Dodaje nowoczesny gradient."""
        if colors is None:
            colors = ["#667eea", "#764ba2"]
            
        if direction == "horizontal":
            start, end = (0, 0), (self.width, 0)
        elif direction == "vertical":
            start, end = (0, 0), (0, self.height)
        else:  # diagonal
            start, end = (0, 0), (self.width, self.height)
            
        gradient = self.dwg.linearGradient(
            start=start, 
            end=end,
            id="adGradient"
        )
        
        for i, color in enumerate(colors):
            gradient.add_stop_color(offset=f"{i * 100 / (len(colors) - 1)}%", color=color)
        
        self.dwg.defs.add(gradient)
        
        self.dwg.add(self.dwg.rect(
            insert=(0, 0),
            size=(self.width, self.height),
            fill="url(#adGradient)"
        ))
        
        return self
    
    def add_abstract_shapes(self, count: int = 10,
                            opacity: float = 0.1) -> 'SVGAdvertisementBackground':
        """Dodaje abstrakcyjne kształty."""
        import random
        random.seed(42)  # Dla powtarzalności
        
        colors = ["#ffffff", "#f0f0f0", "#e0e0e0"]
        
        for _ in range(count):
            shape_type = random.choice(["circle", "rect", "polygon"])
            x = random.randint(0, self.width)
            y = random.randint(0, self.height)
            size = random.randint(50, 300)
            color = random.choice(colors)
            
            if shape_type == "circle":
                self.dwg.add(self.dwg.circle(
                    center=(x, y),
                    r=size/2,
                    fill=color,
                    opacity=opacity
                ))
            elif shape_type == "rect":
                self.dwg.add(self.dwg.rect(
                    insert=(x - size/2, y - size/2),
                    size=(size, size),
                    fill=color,
                    opacity=opacity,
                    rx=size * 0.1
                ))
            else:  # polygon - trójkąt
                points = [(x, y-size/2), (x+size/2, y+size/2), (x-size/2, y+size/2)]
                self.dwg.add(self.dwg.polygon(
                    points=points,
                    fill=color,
                    opacity=opacity
                ))
        
        return self
    
    def add_overlay_grid(self, cell_size: int = 50,
                         color: str = "#ffffff",
                         opacity: float = 0.05) -> 'SVGAdvertisementBackground':
        """Dodaje siatkę jako overlay."""
        # Linie pionowe
        for x in range(0, self.width + cell_size, cell_size):
            self.dwg.add(self.dwg.line(
                start=(x, 0),
                end=(x, self.height),
                stroke=color,
                stroke_width=0.5,
                opacity=opacity
            ))
            
        # Linie poziome
        for y in range(0, self.height + cell_size, cell_size):
            self.dwg.add(self.dwg.line(
                start=(0, y),
                end=(self.width, y),
                stroke=color,
                stroke_width=0.5,
                opacity=opacity
            ))
        
        return self
    
    def save(self, filename: str) -> str:
        """Zapisuje plik SVG."""
        output_path = Path(filename)
        if not output_path.suffix.lower() == '.svg':
            output_path = output_path.with_suffix('.svg')
        
        self.dwg.saveas(str(output_path))
        return str(output_path)
    
    def generate(self, output_file: str,
                 gradient_colors: List[str] = None,
                 with_shapes: bool = True,
                 with_grid: bool = False) -> str:
        """Generuje kompletne tło reklamy."""
        self.add_modern_gradient(colors=gradient_colors)
        
        if with_shapes:
            self.add_abstract_shapes()
            
        if with_grid:
            self.add_overlay_grid()
            
        return self.save(output_file)


class JPGToSVGConverter:
    """Konwerter obrazków JPG/PNG na SVG."""
    
    def __init__(self):
        if not PIL_AVAILABLE:
            raise ImportError("Pillow (PIL) jest wymagany do konwersji JPG->SVG")
    
    def convert_to_base64_embedded(self, input_path: str, 
                                   output_path: str) -> str:
        """
        Konwertuje JPG/PNG na SVG z osadzonym obrazkiem (base64).
        To najprostsza metoda zachowująca pełną jakość oryginału.
        """
        import base64
        from io import BytesIO
        
        input_file = Path(input_path)
        if not input_file.exists():
            raise FileNotFoundError(f"Plik nie znaleziony: {input_path}")
        
        # Otwórz obraz i pobierz wymiary
        with Image.open(input_file) as img:
            width, height = img.size
            
            # Konwersja do RGB jeśli konieczne
            if img.mode in ('RGBA', 'LA', 'P'):
                background = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                img = background
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Zapisz do bufferu
            buffer = BytesIO()
            img.save(buffer, format='JPEG', quality=95)
            img_bytes = buffer.getvalue()
        
        # Zakoduj do base64
        img_base64 = base64.b64encode(img_bytes).decode('utf-8')
        
        # Utwórz SVG
        dwg = svgwrite.Drawing(
            size=(f"{width}px", f"{height}px"),
            viewBox=f"0 0 {width} {height}"
        )
        
        # Dodaj obrazek jako base64 embedded
        image_data = f"data:image/jpeg;base64,{img_base64}"
        dwg.add(dwg.image(
            href=image_data,
            insert=(0, 0),
            size=(width, height)
        ))
        
        # Zapisz
        output_file = Path(output_path)
        if not output_file.suffix.lower() == '.svg':
            output_file = output_file.with_suffix('.svg')
        
        dwg.saveas(str(output_file))
        return str(output_file)
    
    def convert_to_vector_simple(self, input_path: str,
                                 output_path: str,
                                 threshold: int = 128,
                                 scale: int = 1) -> str:
        """
        Prosta wektoryzacja: konwertuje na czarno-biały obraz wektorowy.
        Działa dobrze dla logo, tekstów, prostych grafik.
        """
        input_file = Path(input_path)
        if not input_file.exists():
            raise FileNotFoundError(f"Plik nie znaleziony: {input_path}")
        
        with Image.open(input_file) as img:
            # Skalowanie dla wydajności
            new_size = (img.width // scale, img.height // scale)
            img = img.resize(new_size, Image.Resampling.LANCZOS)
            
            # Konwersja na skalę szarości
            img = img.convert('L')
            
            # Binaryzacja
            img = img.point(lambda p: 255 if p > threshold else 0)
            
            width, height = img.size
        
        # Utwórz SVG
        dwg = svgwrite.Drawing(
            size=(f"{width}px", f"{height}px"),
            viewBox=f"0 0 {width} {height}"
        )
        
        # Przetwórz każdy pixel (dla małych obrazków)
        # Dla większych lepiej użyć algorytmu śledzenia konturów
        pixels = img.load()
        
        # Generowanie prostokątów dla czarnych pikseli
        # Optymalizacja: grupowanie sąsiednich pikseli
        black_rects = []
        
        for y in range(height):
            row_start = None
            for x in range(width):
                if pixels[x, y] == 0:  # Czarny pixel
                    if row_start is None:
                        row_start = x
                else:
                    if row_start is not None:
                        black_rects.append((row_start, y, x - row_start, 1))
                        row_start = None
            if row_start is not None:
                black_rects.append((row_start, y, width - row_start, 1))
        
        # Dodaj prostokąty do SVG
        for x, y, w, h in black_rects:
            dwg.add(dwg.rect(
                insert=(x, y),
                size=(w, h),
                fill="#000000"
            ))
        
        # Zapisz
        output_file = Path(output_path)
        if not output_file.suffix.lower() == '.svg':
            output_file = output_file.with_suffix('.svg')
        
        dwg.saveas(str(output_file))
        return str(output_file)
    
    def create_placeholder_svg(self, width: int, height: int,
                               output_path: str,
                               text: str = "Image Placeholder",
                               bg_color: str = "#f0f0f0",
                               text_color: str = "#666666") -> str:
        """
        Tworzy SVG placeholder o podanych wymiarach.
        """
        dwg = svgwrite.Drawing(
            size=(f"{width}px", f"{height}px"),
            viewBox=f"0 0 {width} {height}"
        )
        
        # Tło
        dwg.add(dwg.rect(
            insert=(0, 0),
            size=(width, height),
            fill=bg_color
        ))
        
        # Ramka
        dwg.add(dwg.rect(
            insert=(0, 0),
            size=(width, height),
            fill="none",
            stroke=text_color,
            stroke_width=2,
            stroke_dasharray="5,5"
        ))
        
        # Tekst
        dwg.add(dwg.text(
            text=text,
            insert=(width/2, height/2),
            fill=text_color,
            text_anchor="middle",
            dominant_baseline="middle",
            font_size=min(width, height) * 0.05,
            font_family="Arial, sans-serif"
        ))
        
        # Wymiary
        dimension_text = f"{width} × {height}"
        dwg.add(dwg.text(
            text=dimension_text,
            insert=(width/2, height/2 + min(width, height) * 0.08),
            fill=text_color,
            text_anchor="middle",
            dominant_baseline="middle",
            font_size=min(width, height) * 0.03,
            font_family="Arial, sans-serif"
        ))
        
        # Zapisz
        output_file = Path(output_path)
        if not output_file.suffix.lower() == '.svg':
            output_file = output_file.with_suffix('.svg')
        
        dwg.saveas(str(output_file))
        return str(output_file)


def main():
    parser = argparse.ArgumentParser(
        description="SVG Graphics Generator & Converter",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Przykłady użycia:
  %(prog)s certificate --output cert_bg.svg
  %(prog)s certificate --output cert.svg --color "#8B4513" --pattern geometric
  %(prog)s advertisement --output ad_bg.svg --colors "#667eea,#764ba2"
  %(prog)s convert --input image.jpg --output image.svg
  %(prog)s convert --input logo.png --output logo_vector.svg --vectorize
  %(prog)s placeholder --width 800 --height 600 --output placeholder.svg
        """
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Dostępne komendy")
    
    # Certificate command
    cert_parser = subparsers.add_parser("certificate", help="Generuj tło certyfikatu")
    cert_parser.add_argument("--output", "-o", default="certificate_background.svg",
                            help="Nazwa pliku wyjściowego")
    cert_parser.add_argument("--width", type=int, default=1920,
                            help="Szerokość (domyślnie: 1920)")
    cert_parser.add_argument("--height", type=int, default=1080,
                            help="Wysokość (domyślnie: 1080)")
    cert_parser.add_argument("--color", "-c", default="#1a5f7a",
                            help="Kolor ramek (domyślnie: #1a5f7a)")
    cert_parser.add_argument("--pattern", "-p", choices=["circles", "lines", "geometric"],
                            default="circles", help="Typ wzoru")
    cert_parser.add_argument("--no-corners", action="store_true",
                            help="Bez ozdobnych rogów")
    
    # Advertisement command
    ad_parser = subparsers.add_parser("advertisement", help="Generuj tło reklamy")
    ad_parser.add_argument("--output", "-o", default="advertisement_background.svg",
                          help="Nazwa pliku wyjściowego")
    ad_parser.add_argument("--width", type=int, default=1920,
                          help="Szerokość (domyślnie: 1920)")
    ad_parser.add_argument("--height", type=int, default=1080,
                          help="Wysokość (domyślnie: 1080)")
    ad_parser.add_argument("--colors", default="#667eea,#764ba2",
                          help="Kolory gradientu (oddzielone przecinkiem)")
    ad_parser.add_argument("--no-shapes", action="store_true",
                          help="Bez abstrakcyjnych kształtów")
    ad_parser.add_argument("--grid", action="store_true",
                          help="Dodaj siatkę overlay")
    
    # Convert command
    conv_parser = subparsers.add_parser("convert", help="Konwertuj JPG/PNG na SVG")
    conv_parser.add_argument("--input", "-i", required=True,
                            help="Plik wejściowy (JPG/PNG)")
    conv_parser.add_argument("--output", "-o", default=None,
                            help="Plik wyjściowy SVG")
    conv_parser.add_argument("--vectorize", "-v", action="store_true",
                            help="Tryb wektoryzacji (czarno-biały)")
    conv_parser.add_argument("--threshold", type=int, default=128,
                            help="Próg binaryzacji (dla --vectorize)")
    conv_parser.add_argument("--scale", type=int, default=1,
                            help="Skala redukcji (dla --vectorize)")
    
    # Placeholder command
    place_parser = subparsers.add_parser("placeholder", help="Utwórz placeholder SVG")
    place_parser.add_argument("--width", type=int, required=True,
                             help="Szerokość")
    place_parser.add_argument("--height", type=int, required=True,
                             help="Wysokość")
    place_parser.add_argument("--output", "-o", default="placeholder.svg",
                             help="Plik wyjściowy")
    place_parser.add_argument("--text", default="Image Placeholder",
                             help="Tekst na placeholderze")
    place_parser.add_argument("--bg-color", default="#f0f0f0",
                             help="Kolor tła")
    place_parser.add_argument("--text-color", default="#666666",
                             help="Kolor tekstu")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        if args.command == "certificate":
            generator = SVGCertificateBackground(width=args.width, height=args.height)
            output = generator.generate(
                output_file=args.output,
                border_color=args.color,
                pattern_type=args.pattern,
                with_corners=not args.no_corners
            )
            print(f"✅ Wygenerowano tło certyfikatu: {output}")
            
        elif args.command == "advertisement":
            colors = [c.strip() for c in args.colors.split(",")]
            generator = SVGAdvertisementBackground(width=args.width, height=args.height)
            output = generator.generate(
                output_file=args.output,
                gradient_colors=colors,
                with_shapes=not args.no_shapes,
                with_grid=args.grid
            )
            print(f"✅ Wygenerowano tło reklamy: {output}")
            
        elif args.command == "convert":
            if not PIL_AVAILABLE:
                print("❌ Błąd: Pillow jest wymagany do konwersji")
                sys.exit(1)
                
            converter = JPGToSVGConverter()
            output = args.output or Path(args.input).with_suffix('.svg').name
            
            if args.vectorize:
                output = converter.convert_to_vector_simple(
                    args.input, output,
                    threshold=args.threshold,
                    scale=args.scale
                )
                print(f"✅ Skonwertowano (wektoryzacja): {output}")
            else:
                output = converter.convert_to_base64_embedded(args.input, output)
                print(f"✅ Skonwertowano (embedded): {output}")
                
        elif args.command == "placeholder":
            if not PIL_AVAILABLE:
                # Fallback bez Pillow
                dwg = svgwrite.Drawing(
                    size=(f"{args.width}px", f"{args.height}px"),
                    viewBox=f"0 0 {args.width} {args.height}"
                )
                dwg.add(dwg.rect(insert=(0, 0), size=(args.width, args.height), fill=args.bg_color))
                dwg.add(dwg.rect(insert=(0, 0), size=(args.width, args.height),
                                fill="none", stroke=args.text_color, stroke_width=2, stroke_dasharray="5,5"))
                dwg.add(dwg.text(text=args.text, insert=(args.width/2, args.height/2),
                                fill=args.text_color, text_anchor="middle", dominant_baseline="middle",
                                font_size=min(args.width, args.height) * 0.05))
                output_file = Path(args.output)
                if not output_file.suffix.lower() == '.svg':
                    output_file = output_file.with_suffix('.svg')
                dwg.saveas(str(output_file))
                print(f"✅ Utworzono placeholder: {output_file}")
            else:
                converter = JPGToSVGConverter()
                output = converter.create_placeholder_svg(
                    args.width, args.height, args.output,
                    text=args.text,
                    bg_color=args.bg_color,
                    text_color=args.text_color
                )
                print(f"✅ Utworzono placeholder: {output}")
        
        print("\n💡 Plik SVG możesz otworzyć w dowolnej przeglądarce lub edytorze grafiki wektorowej.")
        
    except Exception as e:
        print(f"❌ Błąd: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
