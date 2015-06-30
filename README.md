# CTDynamicLibKit
Dynamic Library Kit

## Why to use CTDynamicLibKit?

CTDynamicLibKit is a dynamic library, which can load your customized dynamic library that delivered with your app or even fetched by network.

CTDynamicLibKit provided some methods to load and maintain your dynamic libraries and to call methods(in CTDynamicLibKit, I prefer to call it handler.) from your customized dynamic library.

## Quick Try

1. `cd ./Demo/DynamicDemo` and `pod update`, so that you can use `NVHTarGzip` to extract the framework you will download by network.
2. `cd ./Demo/DynamicLibDemo` and `open DynamicLibDemo.xcodeproj`, press `Command+b` to build it
3. go to `Derived Data`, find the builded `DynamicLibDemo.framework`, then `cd DynamicLibDemo.framework`, use `tar zcvf ../a.tar.gz ./`, and `cd ..` you will see the `a.tar.gz` generated.
4. upload `a.tar.gz` to your own website so that you will have a download URL which looks like `http://1.2.3..4/a.tar.gz`.
5. `open ./Demo/DynamicDemo.xcodeworkspace`, modify `ViewController.m:47` to the correct URL you just generated.
6. press `Command+r` to run DynamicDemo, and wait a few seconds, your app will download and load the framework you just uploaded, and show a UIAlertView.

## How to deploy?
