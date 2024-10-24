package com.demo.docker;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DemoController {


    @GetMapping(value = "/test")
    public String dockerTest(){
        return "Hey from Spring boot application , this application is dockerised and running inside container";
    }

}

