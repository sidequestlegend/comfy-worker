#!/usr/bin/env python
''' Contains the handler function that will be called by the serverless. '''
import json
from urllib import request, parse
import random
import runpod

#this is the one for the default workflow
prompt_text = """
{
  "4": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  "6": {
    "inputs": {
      "text": "daytime sky nature dark blue galaxy bottle",
      "clip": [
        "4",
        1
      ]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "text, watermark",
      "clip": [
        "4",
        1
      ]
    },
    "class_type": "CLIPTextEncode"
  },
  "10": {
    "inputs": {
      "add_noise": "enable",
      "noise_seed": 709640348015191,
      "steps": 25,
      "cfg": 8,
      "sampler_name": "euler",
      "scheduler": "normal",
      "start_at_step": 0,
      "end_at_step": 20,
      "return_with_leftover_noise": "enable",
      "model": [
        "4",
        0
      ],
      "positive": [
        "6",
        0
      ],
      "negative": [
        "7",
        0
      ],
      "latent_image": [
        "5",
        0
      ]
    },
    "class_type": "KSamplerAdvanced"
  },
  "11": {
    "inputs": {
      "add_noise": "disable",
      "noise_seed": 0,
      "steps": 25,
      "cfg": 8,
      "sampler_name": "euler",
      "scheduler": "normal",
      "start_at_step": 20,
      "end_at_step": 10000,
      "return_with_leftover_noise": "disable",
      "model": [
        "12",
        0
      ],
      "positive": [
        "15",
        0
      ],
      "negative": [
        "16",
        0
      ],
      "latent_image": [
        "10",
        0
      ]
    },
    "class_type": "KSamplerAdvanced"
  },
  "12": {
    "inputs": {
      "ckpt_name": "sd_xl_refiner_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "15": {
    "inputs": {
      "text": "daytime scenery  sky nature dark blue bottle with a galaxy stars milky way in it",
      "clip": [
        "12",
        1
      ]
    },
    "class_type": "CLIPTextEncode"
  },
  "16": {
    "inputs": {
      "text": "text, watermark",
      "clip": [
        "12",
        1
      ]
    },
    "class_type": "CLIPTextEncode"
  },
  "17": {
    "inputs": {
      "samples": [
        "11",
        0
      ],
      "vae": [
        "12",
        2
      ]
    },
    "class_type": "VAEDecode"
  },
  "19": {
    "inputs": {
      "filename_prefix": "ComfyUI",
      "images": [
        "17",
        0
      ]
    },
    "class_type": "SaveImage"
  }
}
"""

def queue_prompt(prompt):
    p = {"prompt": prompt}
    data = json.dumps(p).encode('utf-8')
    req =  request.Request("http://127.0.0.1:3000/prompt", data=data)
    request.urlopen(req)

def get_history(prompt_id):
    req =  request.Get("http://127.0.0.1:3000/history/{}".format(prompt_id))
    request.urlopen(req)

def handler(event):
    print(event)
    # queue_prompt(event)
    
    # do the things

    # return the output that you want to be returned like pre-signed URLs to output artifacts
    return "Hello World"

prompt = json.loads(prompt_text)
#set the text prompt for our positive CLIPTextEncode
prompt["6"]["inputs"]["text"] = "masterpiece best quality man"

#set the seed for our KSampler node
prompt["3"]["inputs"]["seed"] = 5

runpod.serverless.start({"handler": handler})
