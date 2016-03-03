
ImageFinder
written by Subash Luitel

Downlods and displays images in a three column collection view based on user query.

Summary of Logic

1. Capture user query from UISearch bar
2. based on the query generate flickr API and perform a NSURLSessionDataTask to get the jSON data of images
3. get image urls from the JSON data
4. download images from image URLs
5. Cache images to memory
6. Store images to disk
7. Display images in the collection view

	- collection view cell first tries to find the image in memory and then disk and then the server
	- images from disk and server are loaded asynchronously to preserve smooth scrolling
	- memory cache is emptied when a new search is perfofrmed
	- memory cache is emptied on a memory warning notification
	- only the recent 10 searches have images stored in disk. older images are deleted
	- image is resized to a smaller size before saving it to the disk or memory

	note: (an alternate way of doing it would be using external libraries such as SDWebImage or FastImageCache etc. that automatically handle image caching)

8. when collection view footer is shown, load another page (repeat 2 to 7)

With more time there still are few improvements I can make to the app. Below are some of the features that I would implement if I had more time.

1. Adjust the size of the collection view cell based on the actual image size
2. When there is an error on loading the next page of images, show a refresh button on the footer of the collection view which users can tap to reload the next page.
3. Cache the searches. So some recent searches are available offline also.

Thank you for taking your time to review my code

Subash Luitel


External Libraries Used

MBProgressHud

Copyright (c) 2009-2015 Matej Bukovinski

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.