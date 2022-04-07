import {
  Component,
  ElementRef,
  Inject,
  ViewChild,
  AfterViewInit,
  OnInit,
} from "@angular/core";
import { ConferenceData } from "../../providers/conference-data";
import { Platform } from "@ionic/angular";
import { DOCUMENT } from "@angular/common";

import { darkStyle } from "./map-dark-style";

const YOUR_GOOGLE_MAPS_API_KEY_HERE = "";
const GOOGLE_MAPS_API_KEY_MIN_LENGTH = 1;
const GOOGLE_MAPS_API_KEY_NOT_CONFIG_MSG1 =
  "Your Google Maps platform API key is not configured in this app.";
const GOOGLE_MAPS_API_KEY_NOT_CONFIG_MSG2 =
  "Please set-up your google cloud console, create the maps API key from the below link, and configure in the app";
const GOOGLE_MAPS_API_KEY_NOT_CONFIG_MSG3 =
  "https://developers.google.com/maps/documentation/maps-static/get-api-key";
@Component({
  selector: "page-map",
  templateUrl: "map.html",
  styleUrls: ["./map.scss"],
})
export class MapPage implements AfterViewInit, OnInit {
  @ViewChild("mapCanvas", { static: true }) mapElement: ElementRef;
  isGoogleMapsAPIKeyConfigured = false;
  userMessage1 = "";
  userMessage2 = "";
  userMessage3 = "";

  constructor(
    @Inject(DOCUMENT) private doc: Document,
    public confData: ConferenceData,
    public platform: Platform
  ) {}

  ngOnInit(): void {
    if (
      YOUR_GOOGLE_MAPS_API_KEY_HERE === null ||
      YOUR_GOOGLE_MAPS_API_KEY_HERE.length < GOOGLE_MAPS_API_KEY_MIN_LENGTH
    ) {
      this.isGoogleMapsAPIKeyConfigured = false;
      this.userMessage1 = GOOGLE_MAPS_API_KEY_NOT_CONFIG_MSG1;
      this.userMessage2 = GOOGLE_MAPS_API_KEY_NOT_CONFIG_MSG2;
      this.userMessage3 = GOOGLE_MAPS_API_KEY_NOT_CONFIG_MSG3;
    } else {
      this.isGoogleMapsAPIKeyConfigured = true;
    }
  }

  async ngAfterViewInit() {
    const appEl = this.doc.querySelector("ion-app");
    let isDark = false;
    let style = [];
    if (appEl.classList.contains("dark-theme")) {
      style = darkStyle;
    }

    if (!this.isGoogleMapsAPIKeyConfigured) {
      // display a message
      return;
    }
    const googleMaps = await getGoogleMaps(YOUR_GOOGLE_MAPS_API_KEY_HERE);

    let map;

    this.confData.getMap().subscribe((mapData: any) => {
      const mapEle = this.mapElement.nativeElement;

      map = new googleMaps.Map(mapEle, {
        center: mapData.find((d: any) => d.center),
        zoom: 16,
        styles: style,
      });

      mapData.forEach((markerData: any) => {
        const infoWindow = new googleMaps.InfoWindow({
          content: `<h5>${markerData.name}</h5>`,
        });

        const marker = new googleMaps.Marker({
          position: markerData,
          map,
          title: markerData.name,
        });

        marker.addListener("click", () => {
          infoWindow.open(map, marker);
        });
      });

      googleMaps.event.addListenerOnce(map, "idle", () => {
        mapEle.classList.add("show-map");
      });
    });

    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === "class") {
          const el = mutation.target as HTMLElement;
          isDark = el.classList.contains("dark-theme");
          if (map && isDark) {
            map.setOptions({ styles: darkStyle });
          } else if (map) {
            map.setOptions({ styles: [] });
          }
        }
      });
    });
    observer.observe(appEl, {
      attributes: true,
    });
  }
}

function getGoogleMaps(apiKey: string): Promise<any> {
  const win = window as any;
  const googleModule = win.google;
  if (googleModule && googleModule.maps) {
    return Promise.resolve(googleModule.maps);
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&v=3.31`;
    script.async = true;
    script.defer = true;
    document.body.appendChild(script);
    script.onload = () => {
      const googleModule2 = win.google;
      if (googleModule2 && googleModule2.maps) {
        resolve(googleModule2.maps);
      } else {
        reject("google maps not available");
      }
    };
  });
}
